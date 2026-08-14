// Mirrors SubcategorySerializer#call exactly — keep in sync with the Rails serializer.
// code is the client's own classification (Bloco Subcategoria) — never an
// invented name/description.
export interface Subcategory {
  id: number;
  code: string;
}

// GET /api/v1/subcategories is deliberately unpaginated (25 rows) — no `meta`.
export interface SubcategoriesResponse {
  data: Subcategory[];
}
