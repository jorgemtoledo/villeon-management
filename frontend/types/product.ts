// Mirrors ProductSerializer#call exactly — keep in sync with the Rails serializer.
import type { PaginationMeta } from "@/types/pagination";

export type { PaginationMeta };

export interface NamedReference {
  id: number;
  name: string;
}

export interface UnitReference extends NamedReference {
  abbreviation: string;
}

// Subcategory is exposed by `code`, not `name` — the client's own code
// (Bloco Subcategoria) IS the classification, never an invented label.
export interface SubcategoryReference {
  id: number;
  code: string;
}

export interface Product {
  id: number;
  name: string;
  code: string;
  colibri_code: string | null;
  conversion_factor: number;
  active: boolean;
  sector: NamedReference | null;
  category: NamedReference | null;
  subcategory: SubcategoryReference | null;
  purchase_unit: UnitReference | null;
  stock_unit: UnitReference | null;
  product_suppliers_count: number;
  // Derived from the product's most recent PurchaseItem/Purchase (Bloco
  // 6H.4) — never a stored column, mirrors "Preço/Data últ. compra" (T/U)
  // in the source spreadsheet. Both null together for a product never
  // purchased; otherwise always come from the same winning row (never one
  // from an older purchase and the other from a newer one).
  last_purchase_price: string | null;
  last_purchase_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProductsResponse {
  data: Product[];
  meta: PaginationMeta;
}

export interface ProductsQuery {
  q?: string;
  sectorId?: number;
  subcategoryId?: number;
  active?: boolean;
  page?: number;
  perPage?: number;
  sort?: "name" | "code" | "created_at";
  order?: "asc" | "desc";
}

// Mirrors Api::V1::ProductsController#product_params exactly — the same
// permitted fields for both POST (create) and PATCH (update); `active` is
// deliberately absent, it only changes via the activate/deactivate endpoints.
export interface ProductInput {
  name: string;
  code: string;
  sector_id: number;
  subcategory_id?: number | null;
  purchase_unit_id: number;
  stock_unit_id: number;
  conversion_factor: number;
  colibri_code?: string | null;
}
