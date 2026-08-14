import { apiRequest } from "@/lib/api/client";
import type { SubcategoriesResponse } from "@/types/subcategory";

export function fetchSubcategories(): Promise<SubcategoriesResponse> {
  return apiRequest<SubcategoriesResponse>("/api/v1/subcategories");
}
