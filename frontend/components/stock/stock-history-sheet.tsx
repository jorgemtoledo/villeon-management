"use client";

import { useProductStockAuditEntries } from "@/hooks/use-stock-audit-entries";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { StockHistoryCards } from "@/components/stock/stock-history-cards";
import {
  StockHistoryEmptyState,
  StockHistoryErrorState,
  StockHistoryLoadingState,
} from "@/components/stock/stock-history-states";

interface StockHistorySheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  product?: { id: number; name: string; code: string };
}

const PER_PAGE = 50;

// Quick per-product access from /estoque (Bloco Histórico #8) — admin/
// manager only, same gate as the general /estoque/historico screen. Always
// reverse-chronological (page 1, most recent 50) — no pagination control
// here on purpose, this is meant as a quick glance, not the full audit
// screen (which already exists at /estoque/historico with real filters and
// pagination for a deeper look).
export function StockHistorySheet({ open, onOpenChange, product }: StockHistorySheetProps) {
  const { data, isPending, isError, refetch } = useProductStockAuditEntries(
    product?.id,
    { perPage: PER_PAGE },
    { enabled: open && product !== undefined },
  );

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-lg">
        <SheetHeader>
          <SheetTitle>Histórico de estoque</SheetTitle>
          <SheetDescription>
            {product ? `${product.name} (${product.code}) — mais recente primeiro.` : ""}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto px-4 py-1">
          {isPending ? <StockHistoryLoadingState /> : null}
          {isError ? <StockHistoryErrorState onRetry={() => refetch()} /> : null}
          {!isPending && !isError && data ? (
            data.data.length === 0 ? (
              <StockHistoryEmptyState />
            ) : (
              // Always the card layout here, never StockHistoryTable — the
              // Sheet panel is a fixed narrow width (max-w-lg) regardless of
              // viewport, so it behaves like a mobile-width container even
              // on a wide desktop screen; a multi-column table would need
              // its own horizontal scroll inside an already-narrow panel.
              <StockHistoryCards entries={data.data} showProduct={false} alwaysVisible />
            )
          ) : null}
        </div>
      </SheetContent>
    </Sheet>
  );
}
