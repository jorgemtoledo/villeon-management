// Mirrors ProductStockSerializer#call exactly — keep in sync with the Rails
// serializer. Decimal columns (current/minimum/ideal/replenishment_quantity)
// come across as strings, same as every other BigDecimal in this API;
// purchase_quantity is a plain Ruby Integer (ROUNDUP result), so it's a number.
import type { NamedReference, UnitReference } from "@/types/product";
import type { PaginationMeta } from "@/types/pagination";

export type StockStatus = "nao_contado" | "ok" | "comprar" | "inativo";

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
}

// Mirrors Api::V1::ProductStocksController#stock_params — the only two
// fields the structural (admin-only) config endpoint accepts.
export interface ProductStockConfigInput {
  minimum_quantity: number;
  ideal_quantity: number;
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
