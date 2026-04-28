import { assertCleanText } from "../_shared/moderation.ts";
import { handleCors } from "../_shared/cors.ts";
import { userIdFromAuthorization } from "../_shared/jwt.ts";
import { ApiError, jsonResponse, readJson, toErrorResponse } from "../_shared/responses.ts";
import { segmentsAfterFunction } from "../_shared/routes.ts";
import { createServiceClient } from "../_shared/supabase.ts";

type PublishChecklistRequest = {
  title?: string;
  description?: string | null;
  icon_name?: string;
  category_id?: string | null;
  language?: string;
  source_checklist_id?: string | null;
  items?: Array<{
    title?: string;
    sort_order?: number;
  }>;
};

type RateChecklistRequest = {
  rating?: number;
};

const checklistSelect = `
  id,
  category_id,
  title,
  description,
  icon_name,
  language,
  version,
  item_count,
  download_count,
  average_rating,
  rating_count,
  created_at,
  author:users!marketplace_checklists_author_id_fkey(display_name)
`;

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const supabase = createServiceClient();
    const segments = segmentsAfterFunction(req, "marketplace");

    if (req.method === "GET" && segments.join("/") === "categories") {
      const { data, error } = await supabase
        .from("categories")
        .select("id, name_key, display_name_tr, display_name_en, icon_name, sort_order, is_active")
        .eq("is_active", true)
        .order("sort_order");

      if (error) {
        throw new ApiError(error.message, 500, "categories_failed");
      }

      return jsonResponse((data ?? []).map(mapCategory));
    }

    if (req.method === "GET" && segments.join("/") === "checklists/featured") {
      const { data, error } = await supabase
        .from("marketplace_checklists")
        .select(checklistSelect)
        .eq("status", "published")
        .order("average_rating", { ascending: false })
        .order("download_count", { ascending: false })
        .order("created_at", { ascending: false })
        .limit(30);

      if (error) {
        throw new ApiError(error.message, 500, "featured_failed");
      }

      return jsonResponse((data ?? []).map((row) => mapChecklist(row)));
    }

    if (
      req.method === "GET"
      && segments.length === 3
      && segments[0] === "categories"
      && segments[2] === "checklists"
    ) {
      const categoryId = segments[1];
      const { data, error } = await supabase
        .from("marketplace_checklists")
        .select(checklistSelect)
        .eq("status", "published")
        .eq("category_id", categoryId)
        .order("created_at", { ascending: false });

      if (error) {
        throw new ApiError(error.message, 500, "category_checklists_failed");
      }

      return jsonResponse((data ?? []).map((row) => mapChecklist(row)));
    }

    if (
      req.method === "GET"
      && segments.length === 2
      && segments[0] === "checklists"
    ) {
      const checklist = await fetchChecklistDetail(supabase, segments[1]);
      return jsonResponse(checklist);
    }

    if (
      req.method === "PUT"
      && segments.length === 2
      && segments[0] === "checklists"
    ) {
      const checklistId = segments[1];
      const userId = await userIdFromAuthorization(req);
      const body = await readJson<PublishChecklistRequest>(req);
      const checklist = await updateChecklist(userId, checklistId, body);
      return jsonResponse(checklist);
    }

    if (
      req.method === "POST"
      && segments.join("/") === "checklists/publish"
    ) {
      const userId = await userIdFromAuthorization(req);
      const body = await readJson<PublishChecklistRequest>(req);
      const checklist = await publishChecklist(userId, body);
      return jsonResponse(checklist, 201);
    }

    if (
      req.method === "GET"
      && segments.length === 3
      && segments[0] === "checklists"
      && segments[2] === "my-rating"
    ) {
      const checklistId = segments[1];
      const userId = await userIdFromAuthorization(req);
      const supabaseClient = createServiceClient();
      const { data } = await supabaseClient
        .from("ratings")
        .select("score")
        .eq("user_id", userId)
        .eq("checklist_id", checklistId)
        .maybeSingle();
      return jsonResponse({ rating: data?.score ?? null });
    }

    if (
      req.method === "POST"
      && segments.length === 3
      && segments[0] === "checklists"
      && segments[2] === "download"
    ) {
      const checklistId = segments[1];
      const userId = await optionalUserIdFromAuthorization(req);
      // Always record in downloads table.
      // • Authenticated: upsert (ignoreDuplicates) → trigger increments count on first download only.
      // • Anonymous: plain insert with user_id=null → trigger always increments count.
      await recordDownload(userId, checklistId);

      const checklist = await fetchChecklistDetail(supabase, checklistId);
      return jsonResponse(checklist);
    }

    if (
      req.method === "POST"
      && segments.length === 3
      && segments[0] === "checklists"
      && segments[2] === "rate"
    ) {
      const checklistId = segments[1];
      const userId = await userIdFromAuthorization(req);
      const body = await readJson<RateChecklistRequest>(req);

      const rating = body.rating;
      if (!Number.isInteger(rating) || (rating as number) < 1 || (rating as number) > 5) {
        throw new ApiError("Rating must be an integer between 1 and 5.", 400, "invalid_rating");
      }

      await upsertRating(userId, checklistId, rating as number);

      const checklist = await fetchChecklistDetail(supabase, checklistId);
      return jsonResponse(checklist);
    }

    throw new ApiError("Route not found.", 404, "not_found");
  } catch (error) {
    return toErrorResponse(error);
  }
});

async function fetchChecklistDetail(
  supabase: ReturnType<typeof createServiceClient>,
  checklistId: string,
) {
  const { data: checklist, error } = await supabase
    .from("marketplace_checklists")
    .select(checklistSelect)
    .eq("id", checklistId)
    .eq("status", "published")
    .single();

  if (error || !checklist) {
    throw new ApiError("Checklist not found.", 404, "checklist_not_found");
  }

  const { data: items, error: itemsError } = await supabase
    .from("marketplace_checklist_items")
    .select("id, title, sort_order")
    .eq("checklist_id", checklistId)
    .order("sort_order");

  if (itemsError) {
    throw new ApiError(itemsError.message, 500, "checklist_items_failed");
  }

  return mapChecklist(checklist, (items ?? []).map(mapChecklistItem));
}

async function publishChecklist(userId: string, body: PublishChecklistRequest) {
  const supabase = createServiceClient();
  const title = body.title?.trim();
  const description = body.description?.trim() || null;
  const iconName = body.icon_name?.trim() || "checklist";
  const language = body.language?.trim() || "en";
  const items = (body.items ?? [])
    .map((item, index) => ({
      title: item.title?.trim() ?? "",
      sort_order: Number.isInteger(item.sort_order) ? item.sort_order as number : index,
    }))
    .filter((item) => item.title.length > 0);

  if (!title) {
    throw new ApiError("Checklist title is required.", 400, "missing_title");
  }

  if (items.length === 0) {
    throw new ApiError("At least one checklist item is required.", 400, "missing_items");
  }

  assertCleanText(title, description, ...items.map((item) => item.title));

  const { data: user, error: userError } = await supabase
    .from("users")
    .select("id, is_banned")
    .eq("id", userId)
    .single();

  if (userError || !user) {
    throw new ApiError("Marketplace user not found.", 401, "user_not_found");
  }

  if (user.is_banned) {
    throw new ApiError("This marketplace user has been suspended.", 403, "user_banned");
  }

  const dayStart = new Date();
  dayStart.setUTCHours(0, 0, 0, 0);

  const { count, error: countError } = await supabase
    .from("marketplace_checklists")
    .select("id", { count: "exact", head: true })
    .eq("author_id", userId)
    .gte("created_at", dayStart.toISOString());

  if (countError) {
    throw new ApiError(countError.message, 500, "rate_limit_check_failed");
  }

  if ((count ?? 0) >= 5) {
    throw new ApiError("Daily publish limit reached.", 429, "publish_rate_limited");
  }

  const { data: checklist, error: checklistError } = await supabase
    .from("marketplace_checklists")
    .insert({
      author_id: userId,
      category_id: body.category_id ?? null,
      title,
      description,
      icon_name: iconName,
      language,
      item_count: items.length,
      status: "published",
      source_checklist_id: body.source_checklist_id ?? null,
    })
    .select("id")
    .single();

  if (checklistError || !checklist) {
    throw new ApiError(checklistError?.message ?? "Checklist publish failed.", 500, "publish_failed");
  }

  const { error: itemsError } = await supabase
    .from("marketplace_checklist_items")
    .insert(items.map((item) => ({
      checklist_id: checklist.id,
      title: item.title,
      sort_order: item.sort_order,
    })));

  if (itemsError) {
    await supabase.from("marketplace_checklists").delete().eq("id", checklist.id);
    throw new ApiError(itemsError.message, 500, "publish_items_failed");
  }

  return await fetchChecklistDetail(supabase, checklist.id);
}

async function updateChecklist(userId: string, checklistId: string, body: PublishChecklistRequest) {
  const supabase = createServiceClient();

  const title = body.title?.trim();
  const description = body.description?.trim() || null;
  const iconName = body.icon_name?.trim() || "checklist";
  const language = body.language?.trim() || "en";
  const items = (body.items ?? [])
    .map((item, index) => ({
      title: item.title?.trim() ?? "",
      sort_order: Number.isInteger(item.sort_order) ? item.sort_order as number : index,
    }))
    .filter((item) => item.title.length > 0);

  if (!title) throw new ApiError("Checklist title is required.", 400, "missing_title");
  if (items.length === 0) throw new ApiError("At least one checklist item is required.", 400, "missing_items");

  assertCleanText(title, description, ...items.map((i) => i.title));

  // Verify ownership
  const { data: existing, error: fetchError } = await supabase
    .from("marketplace_checklists")
    .select("id, author_id, version")
    .eq("id", checklistId)
    .single();

  if (fetchError || !existing) throw new ApiError("Checklist not found.", 404, "checklist_not_found");
  if (existing.author_id !== userId) throw new ApiError("Not authorized.", 403, "not_authorized");

  const { error: updateError } = await supabase
    .from("marketplace_checklists")
    .update({
      title,
      description,
      icon_name: iconName,
      category_id: body.category_id ?? null,
      language,
      item_count: items.length,
      version: (existing.version as number) + 1,
      status: "published",
    })
    .eq("id", checklistId);

  if (updateError) throw new ApiError(updateError.message, 500, "update_failed");

  // Replace items
  await supabase.from("marketplace_checklist_items").delete().eq("checklist_id", checklistId);

  const { error: itemsError } = await supabase
    .from("marketplace_checklist_items")
    .insert(items.map((item) => ({
      checklist_id: checklistId,
      title: item.title,
      sort_order: item.sort_order,
    })));

  if (itemsError) throw new ApiError(itemsError.message, 500, "update_items_failed");

  return await fetchChecklistDetail(supabase, checklistId);
}

async function recordDownload(userId: string | null, checklistId: string): Promise<void> {
  const supabase = createServiceClient();

  if (userId) {
    // Authenticated: upsert so the same user is recorded only once per checklist.
    // The DB trigger increments download_count only on a real INSERT.
    const { error } = await supabase
      .from("downloads")
      .upsert(
        { user_id: userId, checklist_id: checklistId },
        { onConflict: "user_id,checklist_id", ignoreDuplicates: true },
      );
    if (error) throw new ApiError(error.message, 500, "download_record_failed");
  } else {
    // Anonymous: insert with user_id = null; each download is a separate row.
    // The DB trigger increments download_count on every insert.
    const { error } = await supabase
      .from("downloads")
      .insert({ user_id: null, checklist_id: checklistId });
    if (error) throw new ApiError(error.message, 500, "download_record_failed");
  }
}

async function upsertRating(userId: string, checklistId: string, score: number): Promise<void> {
  const supabase = createServiceClient();

  // Check user exists and is not banned
  const { data: user, error: userError } = await supabase
    .from("users")
    .select("id, is_banned")
    .eq("id", userId)
    .single();

  if (userError || !user) {
    throw new ApiError("Marketplace user not found.", 401, "user_not_found");
  }

  if (user.is_banned) {
    throw new ApiError("This marketplace user has been suspended.", 403, "user_banned");
  }

  const { error } = await supabase
    .from("ratings")
    .upsert(
      { user_id: userId, checklist_id: checklistId, score },
      { onConflict: "user_id,checklist_id" },
    );

  if (error) {
    throw new ApiError(error.message, 500, "rating_failed");
  }
  // NOTE: The `ratings_refresh_summary_*` DB triggers automatically recalculate
  // `average_rating` and `rating_count` on marketplace_checklists.
}

async function optionalUserIdFromAuthorization(req: Request): Promise<string | null> {
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return null;
  }

  try {
    return await userIdFromAuthorization(req);
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) {
      return null;
    }

    throw error;
  }
}

function mapCategory(row: Record<string, unknown>) {
  return {
    id: row.id,
    nameKey: row.name_key,
    displayNameTr: row.display_name_tr,
    displayNameEn: row.display_name_en,
    iconName: row.icon_name,
    sortOrder: row.sort_order,
    isActive: row.is_active,
  };
}

function mapChecklist(row: Record<string, unknown>, items?: Array<Record<string, unknown>>) {
  const author = row.author as { display_name?: string } | null;

  return {
    id: row.id,
    authorDisplayName: author?.display_name ?? "Anonymous",
    categoryId: row.category_id,
    title: row.title,
    description: row.description,
    iconName: row.icon_name,
    language: row.language,
    version: row.version,
    itemCount: row.item_count,
    downloadCount: row.download_count,
    averageRating: Number(row.average_rating ?? 0),
    ratingCount: row.rating_count,
    items: Array.isArray(items) ? items : undefined,
    createdAt: formatDate(row.created_at),
  };
}

function mapChecklistItem(row: Record<string, unknown>) {
  return {
    id: row.id,
    title: row.title,
    sortOrder: row.sort_order,
  };
}

function formatDate(value: unknown) {
  if (typeof value !== "string") {
    return value;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}
