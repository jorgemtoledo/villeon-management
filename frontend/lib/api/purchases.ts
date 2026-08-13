import { apiRequest } from "@/lib/api/client";
import type { PurchaseDetail, PurchaseInput, PurchasesQuery, PurchasesResponse } from "@/types/purchase";

function buildQueryString(query: PurchasesQuery): string {
  const params = new URLSearchParams();

  if (query.q) params.set("q", query.q);
  if (query.supplierId) params.set("supplier_id", String(query.supplierId));
  if (query.dateFrom) params.set("date_from", query.dateFrom);
  if (query.dateTo) params.set("date_to", query.dateTo);
  if (query.page) params.set("page", String(query.page));
  if (query.perPage) params.set("per_page", String(query.perPage));
  if (query.sort) params.set("sort", query.sort);
  if (query.order) params.set("order", query.order);

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function fetchPurchases(query: PurchasesQuery): Promise<PurchasesResponse> {
  return apiRequest<PurchasesResponse>(`/api/v1/purchases${buildQueryString(query)}`);
}

export function fetchPurchase(id: number | string): Promise<PurchaseDetail> {
  return apiRequest<PurchaseDetail>(`/api/v1/purchases/${id}`);
}

export function createPurchase(input: PurchaseInput): Promise<PurchaseDetail> {
  return apiRequest<PurchaseDetail>("/api/v1/purchases", {
    method: "POST",
    body: JSON.stringify({ purchase: input }),
  });
}

export function updatePurchase(id: number | string, input: PurchaseInput): Promise<PurchaseDetail> {
  return apiRequest<PurchaseDetail>(`/api/v1/purchases/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ purchase: input }),
  });
}
