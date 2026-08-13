// Stock quantities (current/minimum/ideal/replenishment) come from the API
// as decimal strings (e.g. "12.0000") — this only formats for display
// (drops insignificant trailing zeros), it never recomputes anything the
// backend already calculated.
export function formatStockQuantity(value: string | null): string {
  if (value === null) return "—";

  return new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 4 }).format(Number(value));
}
