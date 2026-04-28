import { ApiError } from "./responses.ts";

const blockedTerms = [
  "spam",
  "scam",
  "casino",
  "crypto profit",
];

export function assertCleanText(...values: Array<string | null | undefined>): void {
  const combined = values
    .filter((value): value is string => typeof value === "string")
    .join(" ")
    .toLocaleLowerCase("en-US");

  if (blockedTerms.some((term) => combined.includes(term))) {
    throw new ApiError("Content failed marketplace moderation checks.", 400, "moderation_failed");
  }
}
