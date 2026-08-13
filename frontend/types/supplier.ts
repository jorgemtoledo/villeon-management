// Mirrors SupplierSerializer#call exactly — keep in sync with the Rails serializer.
import type { PaginationMeta } from "@/types/pagination";

export interface Supplier {
  id: number;
  name: string;
  cnpj: string | null;
  active: boolean;
  products_count: number;
  created_at: string;
  updated_at: string;
}

export interface SuppliersResponse {
  data: Supplier[];
  meta: PaginationMeta;
}

export interface SuppliersQuery {
  q?: string;
  active?: boolean;
  page?: number;
  perPage?: number;
  sort?: "name" | "cnpj" | "created_at";
  order?: "asc" | "desc";
}

// Mirrors Api::V1::SuppliersController#supplier_params exactly — same
// permitted fields for both POST (create) and PATCH (update); `active` is
// deliberately absent, it only changes via the activate/deactivate endpoints.
export interface SupplierInput {
  name: string;
  cnpj?: string | null;
}

// Mirrors SupplierProductSerializer#call — the pivot (ProductSupplier) plus
// the referenced Product's own identifying fields. Not a full Product.
export interface SupplierProduct {
  id: number;
  name: string;
  code: string;
  supplier_product_code: string | null;
  preferred: boolean;
  notes: string | null;
}

export interface SupplierProductsResponse {
  data: SupplierProduct[];
  meta: PaginationMeta;
}

export interface SupplierProductsQuery {
  page?: number;
  perPage?: number;
}
