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

export interface Product {
  id: number;
  name: string;
  code: string;
  colibri_code: string | null;
  conversion_factor: number;
  active: boolean;
  sector: NamedReference | null;
  category: NamedReference | null;
  subcategory: NamedReference | null;
  purchase_unit: UnitReference | null;
  stock_unit: UnitReference | null;
  product_suppliers_count: number;
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
  purchase_unit_id: number;
  stock_unit_id: number;
  conversion_factor: number;
  colibri_code?: string | null;
}
