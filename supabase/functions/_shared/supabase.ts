import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.48.1";
import { ApiError } from "./responses.ts";

export function createServiceClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    throw new ApiError("Supabase service credentials are not configured.", 500, "missing_supabase_env");
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
