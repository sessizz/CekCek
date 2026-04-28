export function segmentsAfterFunction(req: Request, functionName: string): string[] {
  const pathname = new URL(req.url).pathname;
  const segments = pathname.split("/").filter(Boolean);
  const functionIndex = segments.indexOf(functionName);

  if (functionIndex === -1) {
    return segments;
  }

  return segments.slice(functionIndex + 1);
}
