import { apiRequest } from "@/lib/api/client";
import type {
  StockAuditEntriesQuery,
  StockAuditEntriesResponse,
  StockAuditUsersResponse,
} from "@/types/stock-audit";

function buildQueryString(query: StockAuditEntriesQuery): string {
  const params = new URLSearchParams();

  if (query.q) params.set("q", query.q);
  if (query.userId) params.set("user_id", String(query.userId));
  if (query.field) params.set("field", query.field);
  if (query.dateFrom) params.set("date_from", query.dateFrom);
  if (query.dateTo) params.set("date_to", query.dateTo);
  if (query.page) params.set("page", String(query.page));
  if (query.perPage) params.set("per_page", String(query.perPage));

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function fetchStockAuditEntries(query: StockAuditEntriesQuery): Promise<StockAuditEntriesResponse> {
  return apiRequest<StockAuditEntriesResponse>(`/api/v1/stock_audit_entries${buildQueryString(query)}`);
}

export function fetchProductStockAuditEntries(
  productId: number,
  query: StockAuditEntriesQuery = {},
): Promise<StockAuditEntriesResponse> {
  return apiRequest<StockAuditEntriesResponse>(
    `/api/v1/products/${productId}/stock_audit_entries${buildQueryString(query)}`,
  );
}

export function fetchStockAuditUsers(): Promise<StockAuditUsersResponse> {
  return apiRequest<StockAuditUsersResponse>("/api/v1/stock_audit_entries/users");
}
