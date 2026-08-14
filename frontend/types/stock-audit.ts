// Mirrors StockAuditEntrySerializer#call exactly — keep in sync with the
// Rails serializer.
import type { PaginationMeta } from "@/types/pagination";

// Mirrors StockAuditEntry::FIELDS exactly — the only three auditable fields
// (Bloco Histórico). Never minimum_quantity/ideal_quantity.
export type StockAuditField = "current_quantity" | "priority" | "needs_advance_order";

export interface StockAuditEntry {
  id: number;
  product: { id: number; name: string; code: string };
  user: { id: number; name: string };
  field: StockAuditField;
  // Always the raw underlying value as a string (e.g. "12.0", "critical",
  // "true"), never a human label — formatting happens on display, same
  // split as every other enum/boolean field in this app.
  previous_value: string | null;
  new_value: string | null;
  created_at: string;
}

export interface StockAuditEntriesResponse {
  data: StockAuditEntry[];
  meta: PaginationMeta;
}

export interface StockAuditEntriesQuery {
  q?: string;
  userId?: number;
  field?: StockAuditField;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  perPage?: number;
}

export interface StockAuditUser {
  id: number;
  name: string;
}

export interface StockAuditUsersResponse {
  data: StockAuditUser[];
}
