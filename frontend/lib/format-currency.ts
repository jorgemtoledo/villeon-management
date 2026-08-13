// Purchase monetary fields (total_amount, unit_price, total_price) arrive as
// strings from the API (Rails BigDecimal#as_json), never as number — see
// types/purchase.ts. This is the single place that turns them into a
// pt-BR/BRL display string.
export function formatCurrency(value: string): string {
  return Number(value).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}
