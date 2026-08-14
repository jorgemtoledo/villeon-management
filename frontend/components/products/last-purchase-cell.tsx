import { formatCurrency } from "@/lib/format-currency";
import { formatDate } from "@/lib/format-date";
import type { Product } from "@/types/product";

interface LastPurchaseCellProps {
  product: Pick<Product, "last_purchase_price" | "last_purchase_date">;
}

// Bloco 6H.4 — shared between ProductsTable and ProductsCards. Both fields
// always arrive together from the API (same PurchaseItem/Purchase row) or
// both null (never purchased) — never a mix, so a single presence check
// covers both.
export function LastPurchaseCell({ product }: LastPurchaseCellProps) {
  if (product.last_purchase_price === null || product.last_purchase_date === null) {
    return <span className="text-sm text-muted-foreground">A definir</span>;
  }

  return (
    <span className="text-sm">
      {formatDate(product.last_purchase_date)} · {formatCurrency(product.last_purchase_price)}
    </span>
  );
}
