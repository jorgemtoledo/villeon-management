import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency } from "@/lib/format-currency";
import type { PurchaseItem } from "@/types/purchase";

// Mobile only (<md / 768px) — see PurchaseItemsTable for desktop/tablet.
export function PurchaseItemsCards({ items }: { items: PurchaseItem[] }) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {items.map((item) => (
        <Card key={item.id}>
          <CardContent className="flex flex-col gap-3 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-medium text-foreground">{item.product.name}</p>
                <p className="text-xs text-muted-foreground">{item.product.code}</p>
              </div>
              <p className="font-medium text-foreground">{formatCurrency(item.total_price)}</p>
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              <dt className="text-muted-foreground">Quantidade</dt>
              <dd>
                {Number(item.quantity).toLocaleString("pt-BR")} {item.unit?.abbreviation ?? ""}
              </dd>
              <dt className="text-muted-foreground">Preço unitário</dt>
              <dd>{formatCurrency(item.unit_price)}</dd>
            </dl>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
