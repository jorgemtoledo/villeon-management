import type { StockStatus } from "@/types/product-stock";

// Mirrors StockCalculator's four possible values exactly — never invent a
// fifth state here, the backend is the only source of truth for status.
export const STOCK_STATUS_LABEL: Record<StockStatus, string> = {
  nao_contado: "Não contado",
  ok: "OK",
  comprar: "Comprar",
  inativo: "Inativo",
};

export const STOCK_STATUS_BADGE_VARIANT: Record<StockStatus, "secondary" | "outline" | "destructive"> = {
  nao_contado: "secondary",
  ok: "outline",
  comprar: "destructive",
  inativo: "secondary",
};
