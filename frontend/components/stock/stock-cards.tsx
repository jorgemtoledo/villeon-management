import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_STATUS_BADGE_VARIANT, STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import { StockPurchaseConfigCell } from "@/components/stock/stock-purchase-config-cell";
import type { ProductStock } from "@/types/product-stock";

interface StockCardsProps {
  rows: ProductStock[];
  onCount: (row: ProductStock) => void;
  onConfigurePriority: (row: ProductStock) => void;
}

// Mobile only (<md / 768px) — a 9-column table doesn't fit a phone screen
// without horizontal scroll, so it becomes a stacked card list here instead
// of the StockTable used on md+.
export function StockCards({ rows, onCount, onConfigurePriority }: StockCardsProps) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {rows.map((row) => (
        <Card key={row.product.id}>
          <CardContent className="flex flex-col gap-3 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-medium text-foreground">{row.product.name}</p>
                <p className="text-xs text-muted-foreground">{row.product.code}</p>
              </div>
              <Badge variant={STOCK_STATUS_BADGE_VARIANT[row.status]}>{STOCK_STATUS_LABEL[row.status]}</Badge>
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              <dt className="text-muted-foreground">Unidade</dt>
              <dd>{row.stock_unit?.abbreviation ?? "—"}</dd>
              <dt className="text-muted-foreground">Estoque atual</dt>
              <dd>{formatStockQuantity(row.current_quantity)}</dd>
              <dt className="text-muted-foreground">Mínimo</dt>
              <dd>{formatStockQuantity(row.minimum_quantity)}</dd>
              <dt className="text-muted-foreground">Ideal</dt>
              <dd>{formatStockQuantity(row.ideal_quantity)}</dd>
              <dt className="text-muted-foreground">Reposição</dt>
              <dd>{formatStockQuantity(row.replenishment_quantity)}</dd>
              <dt className="text-muted-foreground">Comprar</dt>
              <dd>{row.purchase_quantity ?? "—"}</dd>
            </dl>

            <div className="flex flex-col gap-1 border-t border-border pt-3">
              <span className="text-xs font-medium text-muted-foreground">Configuração de compra</span>
              <StockPurchaseConfigCell row={row} onConfigure={onConfigurePriority} />
            </div>

            <Button type="button" variant="outline" className="h-11 w-full" onClick={() => onCount(row)}>
              {row.status === "nao_contado" ? "Contar" : "Atualizar contagem"}
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
