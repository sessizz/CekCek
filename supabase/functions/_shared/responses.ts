import { corsHeaders } from "./cors.ts";

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function errorResponse(message: string, status = 400, code = "bad_request"): Response {
  return jsonResponse({ error: { code, message } }, status);
}

export async function readJson<T>(req: Request): Promise<T> {
  try {
    return await req.json() as T;
  } catch {
    throw new ApiError("Invalid JSON body.", 400, "invalid_json");
  }
}

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status = 400,
    public readonly code = "bad_request",
  ) {
    super(message);
  }
}

export function toErrorResponse(error: unknown): Response {
  if (error instanceof ApiError) {
    return errorResponse(error.message, error.status, error.code);
  }

  const message = error instanceof Error ? error.message : "Unexpected server error.";
  return errorResponse(message, 500, "server_error");
}
