import { Card, CardContent } from "@/components/ui/card";
import { formatDateTime } from "@/lib/format-date";
import { STOCK_AUDIT_FIELD_LABEL, formatStockAuditValue } from "@/lib/format-stock-audit";
import { cn } from "@/lib/utils";
import type { StockAuditEntry } from "@/types/stock-audit";

interface StockHistoryCardsProps {
  entries: StockAuditEntry[];
  showProduct?: boolean;
  // true when rendered inside StockHistorySheet — a Sheet panel is a fixed
  // narrow width regardless of viewport, so it must always use the card
  // layout, even at desktop viewport widths (where `md:hidden` would
  // otherwise hide it).
  alwaysVisible?: boolean;
}

// Mobile only (<md / 768px) by default — see StockHistoryTable for the
// desktop equivalent.
export function StockHistoryCards({ entries, showProduct = true, alwaysVisible = false }: StockHistoryCardsProps) {
  return (
    <div className={cn("flex flex-col gap-3", !alwaysVisible && "md:hidden")}>
      {entries.map((entry) => (
        <Card key={entry.id}>
          <CardContent className="flex flex-col gap-2 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                {showProduct ? (
                  <>
                    <p className="font-medium text-foreground">{entry.product.name}</p>
                    <p className="text-xs text-muted-foreground">{entry.product.code}</p>
                  </>
                ) : (
                  <p className="font-medium text-foreground">{STOCK_AUDIT_FIELD_LABEL[entry.field]}</p>
                )}
              </div>
              <p className="text-xs text-muted-foreground">{formatDateTime(entry.created_at)}</p>
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              {showProduct ? (
                <>
                  <dt className="text-muted-foreground">Alteração</dt>
                  <dd>{STOCK_AUDIT_FIELD_LABEL[entry.field]}</dd>
                </>
              ) : null}
              <dt className="text-muted-foreground">Usuário</dt>
              <dd>{entry.user.name}</dd>
              <dt className="text-muted-foreground">Antes</dt>
              <dd>{formatStockAuditValue(entry.field, entry.previous_value)}</dd>
              <dt className="text-muted-foreground">Depois</dt>
              <dd>{formatStockAuditValue(entry.field, entry.new_value)}</dd>
            </dl>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
