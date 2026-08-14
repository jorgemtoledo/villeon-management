import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_PRIORITY_LABEL } from "@/lib/format-stock-status";
import type { StockPriority } from "@/types/product-stock";
import type { StockAuditField } from "@/types/stock-audit";

// Mirrors StockAuditEntry::FIELDS exactly (Bloco Histórico).
export const STOCK_AUDIT_FIELD_LABEL: Record<StockAuditField, string> = {
  current_quantity: "Estoque atual",
  priority: "Prioridade",
  needs_advance_order: "Pedir c/ antecedência",
};

// previous_value/new_value always arrive as the raw underlying value
// (decimal string, enum string, or "true"/"false") — this is the one place
// that turns them into the same human labels already used elsewhere in the
// app (StockPriorityStep, StockPurchaseConfigCell). "A definir" for null
// matches the client's own example ("Prioridade: A definir → Crítico"),
// distinct from the "—" convention used for absent table cells elsewhere.
export function formatStockAuditValue(field: StockAuditField, value: string | null): string {
  if (field === "current_quantity") return formatStockQuantity(value);
  if (value === null) return "A definir";
  if (field === "priority") return STOCK_PRIORITY_LABEL[value as StockPriority] ?? value;

  return value === "true" ? "Sim" : "Não";
}
