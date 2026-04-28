import { handleCors } from "../_shared/cors.ts";
import { base64Url, signHS256 } from "../_shared/jwt.ts";
import { ApiError, jsonResponse, readJson, toErrorResponse } from "../_shared/responses.ts";
import { segmentsAfterFunction } from "../_shared/routes.ts";
import { createServiceClient } from "../_shared/supabase.ts";

type CloudKitLoginRequest = {
  cloudkit_user_id?: string;
  device_check_token?: string;
  display_name?: string;
};

const encoder = new TextEncoder();

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const segments = segmentsAfterFunction(req, "marketplace-auth");
    if (req.method !== "POST" || segments.join("/") !== "cloudkit-login") {
      throw new ApiError("Route not found.", 404, "not_found");
    }

    const body = await readJson<CloudKitLoginRequest>(req);
    const cloudKitUserId = body.cloudkit_user_id?.trim();

    if (!cloudKitUserId) {
      throw new ApiError("cloudkit_user_id is required.", 400, "missing_cloudkit_user_id");
    }

    await verifyDeviceCheckToken(body.device_check_token);

    const supabase = createServiceClient();
    const displayName = cleanDisplayName(body.display_name);

    const upsertPayload: Record<string, string> = {
      cloudkit_user_id: cloudKitUserId,
    };

    if (displayName) {
      upsertPayload.display_name = displayName;
    }

    const { data: user, error } = await supabase
      .from("users")
      .upsert(upsertPayload, { onConflict: "cloudkit_user_id" })
      .select("id, cloudkit_user_id, display_name, avatar_url, is_banned")
      .single();

    if (error) {
      throw new ApiError(error.message, 500, "user_upsert_failed");
    }

    if (user.is_banned) {
      throw new ApiError("This marketplace user has been suspended.", 403, "user_banned");
    }

    const jwtSecret = Deno.env.get("MARKETPLACE_JWT_SECRET") ?? Deno.env.get("SUPABASE_JWT_SECRET");
    if (!jwtSecret) {
      throw new ApiError("JWT secret is not configured.", 500, "missing_jwt_secret");
    }

    const now = Math.floor(Date.now() / 1000);
    const expiresAt = now + 60 * 60 * 24 * 30;
    const accessToken = await signHS256({
      sub: user.id,
      role: "authenticated",
      aud: "authenticated",
      iat: now,
      exp: expiresAt,
      iss: "cekcek-marketplace",
    }, jwtSecret);

    return jsonResponse({
      access_token: accessToken,
      expires_at: expiresAt,
      user: {
        id: user.id,
        cloudkit_user_id: user.cloudkit_user_id,
        display_name: user.display_name,
        avatar_url: user.avatar_url,
      },
    });
  } catch (error) {
    return toErrorResponse(error);
  }
});

function cleanDisplayName(displayName: string | undefined): string | undefined {
  const trimmed = displayName?.trim();
  if (!trimmed) {
    return undefined;
  }

  return trimmed.slice(0, 80);
}

async function verifyDeviceCheckToken(deviceCheckToken: string | undefined): Promise<void> {
  if (Deno.env.get("MARKETPLACE_SKIP_DEVICE_CHECK") === "true") {
    return;
  }

  if (!deviceCheckToken) {
    throw new ApiError("device_check_token is required.", 400, "missing_device_check_token");
  }

  const appleJwt = await createAppleDeviceCheckJWT();
  const environment = Deno.env.get("APPLE_DEVICECHECK_ENV") ?? "development";
  const endpoint = environment === "production"
    ? "https://api.devicecheck.apple.com/v1/query_two_bits"
    : "https://api.development.devicecheck.apple.com/v1/query_two_bits";

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${appleJwt}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      device_token: deviceCheckToken,
      transaction_id: crypto.randomUUID(),
      timestamp: Date.now(),
    }),
  });

  if (!response.ok) {
    const appleBody = await response.text();
    throw new ApiError(
      `DeviceCheck verification failed with ${response.status}: ${appleBody}`,
      401,
      "device_check_failed",
    );
  }
}

async function createAppleDeviceCheckJWT(): Promise<string> {
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const keyId = Deno.env.get("APPLE_KEY_ID");
  const privateKey = Deno.env.get("APPLE_PRIVATE_KEY")?.replaceAll("\\n", "\n");

  if (!teamId || !keyId || !privateKey) {
    throw new ApiError("Apple DeviceCheck credentials are not configured.", 500, "missing_apple_env");
  }

  const header = base64Url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const payload = base64Url(JSON.stringify({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
  }));
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    encoder.encode(signingInput),
  );

  return `${signingInput}.${base64Url(signature)}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes.buffer;
}
