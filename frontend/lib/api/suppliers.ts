import { apiRequest } from "@/lib/api/client";
import type {
  Supplier,
  SupplierInput,
  SuppliersQuery,
  SuppliersResponse,
  SupplierProductsQuery,
  SupplierProductsResponse,
} from "@/types/supplier";

function buildQueryString(params: Record<string, string | number | boolean | undefined>): string {
  const query = new URLSearchParams();

  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined) query.set(key, String(value));
  }

  const qs = query.toString();
  return qs ? `?${qs}` : "";
}

export function fetchSuppliers(query: SuppliersQuery): Promise<SuppliersResponse> {
  const qs = buildQueryString({
    q: query.q,
    active: query.active,
    page: query.page,
    per_page: query.perPage,
    sort: query.sort,
    order: query.order,
  });

  return apiRequest<SuppliersResponse>(`/api/v1/suppliers${qs}`);
}

export function fetchSupplier(id: number | string): Promise<Supplier> {
  return apiRequest<Supplier>(`/api/v1/suppliers/${id}`);
}

export function fetchSupplierProducts(
  id: number | string,
  query: SupplierProductsQuery,
): Promise<SupplierProductsResponse> {
  const qs = buildQueryString({ page: query.page, per_page: query.perPage });

  return apiRequest<SupplierProductsResponse>(`/api/v1/suppliers/${id}/products${qs}`);
}

export function createSupplier(input: SupplierInput): Promise<Supplier> {
  return apiRequest<Supplier>("/api/v1/suppliers", {
    method: "POST",
    body: JSON.stringify({ supplier: input }),
  });
}

export function updateSupplier(id: number, input: SupplierInput): Promise<Supplier> {
  return apiRequest<Supplier>(`/api/v1/suppliers/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ supplier: input }),
  });
}

export function activateSupplier(id: number): Promise<Supplier> {
  return apiRequest<Supplier>(`/api/v1/suppliers/${id}/activate`, { method: "PATCH" });
}

export function deactivateSupplier(id: number): Promise<Supplier> {
  return apiRequest<Supplier>(`/api/v1/suppliers/${id}/deactivate`, { method: "PATCH" });
}
