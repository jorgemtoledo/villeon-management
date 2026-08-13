import { apiRequest } from "@/lib/api/client";
import type { UnitsResponse } from "@/types/unit";

export function fetchUnits(): Promise<UnitsResponse> {
  return apiRequest<UnitsResponse>("/api/v1/units");
}
