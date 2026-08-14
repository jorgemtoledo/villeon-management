import { apiRequest } from "@/lib/api/client";
import type { Product, ProductInput, ProductsQuery, ProductsResponse } from "@/types/product";

function buildQueryString(query: ProductsQuery): string {
  const params = new URLSearchParams();

  if (query.q) params.set("q", query.q);
  if (query.sectorId) params.set("sector_id", String(query.sectorId));
  if (query.subcategoryId) params.set("subcategory_id", String(query.subcategoryId));
  if (query.active !== undefined) params.set("active", String(query.active));
  if (query.page) params.set("page", String(query.page));
  if (query.perPage) params.set("per_page", String(query.perPage));
  if (query.sort) params.set("sort", query.sort);
  if (query.order) params.set("order", query.order);

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function fetchProducts(query: ProductsQuery): Promise<ProductsResponse> {
  return apiRequest<ProductsResponse>(`/api/v1/products${buildQueryString(query)}`);
}

export function createProduct(input: ProductInput): Promise<Product> {
  return apiRequest<Product>("/api/v1/products", {
    method: "POST",
    body: JSON.stringify({ product: input }),
  });
}

export function updateProduct(id: number, input: ProductInput): Promise<Product> {
  return apiRequest<Product>(`/api/v1/products/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ product: input }),
  });
}

export function activateProduct(id: number): Promise<Product> {
  return apiRequest<Product>(`/api/v1/products/${id}/activate`, { method: "PATCH" });
}

export function deactivateProduct(id: number): Promise<Product> {
  return apiRequest<Product>(`/api/v1/products/${id}/deactivate`, { method: "PATCH" });
}
