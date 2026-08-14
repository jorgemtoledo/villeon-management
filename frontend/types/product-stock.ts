// Mirrors ProductStockSerializer#call exactly — keep in sync with the Rails
// serializer. Decimal columns (current/minimum/ideal/replenishment_quantity)
// come across as strings, same as every other BigDecimal in this API;
// purchase_quantity is a plain Ruby Integer (ROUNDUP result), so it's a number.
import type { NamedReference, UnitReference } from "@/types/product";
import type { PaginationMeta } from "@/types/pagination";

export type StockStatus = "nao_contado" | "ok" | "comprar" | "inativo";

// Mirrors ProductStock#priority (Rails enum, backed by a nullable string
// column) — manual business judgment, never derived from status/minimum/etc.
export type StockPriority = "critical" | "normal" | "low";

export interface ProductStock {
  product: { id: number; name: string; code: string; active: boolean };
  sector: NamedReference | null;
  purchase_unit: UnitReference | null;
  stock_unit: UnitReference | null;
  current_quantity: string | null;
  minimum_quantity: string | null;
  ideal_quantity: string | null;
  replenishment_quantity: string | null;
  purchase_quantity: number | null;
  status: StockStatus;
  minimum_configured: boolean;
  // null = never configured, distinct from an explicit "low"/false — same
  // distinction the backend (ProductStock) and the source spreadsheet make.
  priority: StockPriority | null;
  needs_advance_order: boolean | null;
}

// Mirrors Api::V1::ProductStocksController#stock_params — the only two
// fields the structural (admin-only) config endpoint accepts.
export interface ProductStockConfigInput {
  minimum_quantity: number;
  ideal_quantity: number;
}

// Mirrors Api::V1::ProductStocksController#priority_params (the
// sector-scoped, lockable endpoint — separate from the admin-only one
// above). Both optional: either field can be sent on its own.
export interface ProductStockPriorityInput {
  priority?: StockPriority | null;
  needs_advance_order?: boolean | null;
}

export interface ProductStocksResponse {
  data: ProductStock[];
  meta: PaginationMeta;
}

// GET /api/v1/product_stocks only supports these — no free-text search (see
// Bloco 6G Parte 3 report: not implemented, backend has no `q` param for
// this endpoint and none was added, per "don't invent an endpoint").
export interface ProductStocksQuery {
  sectorId?: number;
  active?: boolean;
  page?: number;
  perPage?: number;
}
