import { ApiError } from "./responses.ts";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function base64Url(input: string | Uint8Array | ArrayBuffer): string {
  const bytes = typeof input === "string"
    ? encoder.encode(input)
    : input instanceof ArrayBuffer
    ? new Uint8Array(input)
    : input;

  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function decodeBase64Url(input: string): Uint8Array {
  const normalized = input.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes;
}

async function hmacKey(secret: string, usages: KeyUsage[]): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    usages,
  );
}

export async function signHS256(payload: Record<string, unknown>, secret: string): Promise<string> {
  const header = { alg: "HS256", typ: "JWT" };
  const encodedHeader = base64Url(JSON.stringify(header));
  const encodedPayload = base64Url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await hmacKey(secret, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(signingInput));

  return `${signingInput}.${base64Url(signature)}`;
}

export async function verifyHS256(token: string, secret: string): Promise<Record<string, unknown>> {
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new ApiError("Invalid authorization token.", 401, "invalid_token");
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const key = await hmacKey(secret, ["verify"]);
  const isValid = await crypto.subtle.verify(
    "HMAC",
    key,
    decodeBase64Url(encodedSignature),
    encoder.encode(`${encodedHeader}.${encodedPayload}`),
  );

  if (!isValid) {
    throw new ApiError("Invalid authorization token.", 401, "invalid_token");
  }

  const payload = JSON.parse(decoder.decode(decodeBase64Url(encodedPayload))) as Record<string, unknown>;
  const exp = typeof payload.exp === "number" ? payload.exp : 0;

  if (exp > 0 && exp < Math.floor(Date.now() / 1000)) {
    throw new ApiError("Authorization token has expired.", 401, "expired_token");
  }

  return payload;
}

export async function userIdFromAuthorization(req: Request): Promise<string> {
  const authorization = req.headers.get("Authorization") ?? "";
  const [scheme, token] = authorization.split(" ");

  if (!scheme || !token || scheme.toLowerCase() !== "bearer") {
    throw new ApiError("Authorization is required.", 401, "missing_authorization");
  }

  const jwtSecret = Deno.env.get("MARKETPLACE_JWT_SECRET") ?? Deno.env.get("SUPABASE_JWT_SECRET");
  if (!jwtSecret) {
    throw new ApiError("JWT secret is not configured.", 500, "missing_jwt_secret");
  }

  const payload = await verifyHS256(token, jwtSecret);
  if (payload.role !== "authenticated" || typeof payload.sub !== "string") {
    throw new ApiError("Authorization token is not a marketplace user token.", 401, "invalid_token");
  }

  return payload.sub;
}
