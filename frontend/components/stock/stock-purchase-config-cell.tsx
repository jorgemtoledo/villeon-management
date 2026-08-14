"use client";

import type { ReactNode } from "react";
import { ArrowDownNarrowWide, ArrowUpNarrowWide, Menu, TriangleAlert } from "lucide-react";

import { useAuth } from "@/hooks/use-auth";
import { canEditStockPriority } from "@/lib/auth/permissions";
import { STOCK_PRIORITY_LABEL } from "@/lib/format-stock-status";
import { Badge } from "@/components/ui/badge";
import type { ProductStock, StockPriority } from "@/types/product-stock";

interface StockPurchaseConfigCellProps {
  row: ProductStock;
  onConfigure: (row: ProductStock) => void;
}

const PRIORITY_ICON: Record<StockPriority, typeof ArrowDownNarrowWide> = {
  critical: ArrowDownNarrowWide,
  normal: Menu,
  low: ArrowUpNarrowWide,
};

// Soft-fill treatment, same visual language as Badge's own built-in variants
// (bg-color/10 light, bg-color/20 dark) — critical reuses the "destructive"
// variant verbatim since red is already its color; normal/low don't have a
// built-in orange/blue variant, so they get the same pattern via className
// (twMerge in cn() resolves the override cleanly over the base variant).
const PRIORITY_BADGE_CLASS: Record<StockPriority, string> = {
  critical: "",
  normal: "bg-orange-500/10 text-orange-600 dark:bg-orange-500/20 dark:text-orange-400",
  low: "bg-blue-500/10 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400",
};

function PriorityBadge({ priority }: { priority: StockPriority }) {
  const Icon = PRIORITY_ICON[priority];

  return (
    <Badge
      variant={priority === "critical" ? "destructive" : "secondary"}
      className={PRIORITY_BADGE_CLASS[priority]}
    >
      <Icon aria-hidden="true" />
      {STOCK_PRIORITY_LABEL[priority]}
    </Badge>
  );
}

// Bloco 6G Parte 4.1 — surfaces priority/needs_advance_order in the
// estoque list. Shared verbatim between StockTable and StockCards so the
// wording/thresholds only exist in one place. Purely presentational over
// data the list endpoint already returns (ProductStockSerializer) — no
// per-row fetch, no new backend call, no recomputed business rule: the
// warning only ever appears when status is already "comprar" (computed by
// StockCalculator) and clickability reuses the exact same
// canEditStockPriority the priority step itself already gates on.
export function StockPurchaseConfigCell({ row, onConfigure }: StockPurchaseConfigCellProps) {
  const { user } = useAuth();
  const { priority, needs_advance_order: needsAdvanceOrder, status, sector } = row;

  const fullyConfigured = priority !== null && needsAdvanceOrder !== null;
  const nothingConfigured = priority === null && needsAdvanceOrder === null;
  const pending = status === "comprar" && !fullyConfigured;
  const clickable = status === "comprar" && canEditStockPriority(user, sector?.id, fullyConfigured);

  const advanceText = needsAdvanceOrder === null ? "A definir" : needsAdvanceOrder ? "Sim" : "Não";

  let content: ReactNode;

  if (fullyConfigured && priority) {
    // Priority always comes first, so it's unambiguous without a "Prioridade:"
    // label here — matches the compact example given for this state.
    content = (
      <div className="flex items-center gap-1.5">
        <PriorityBadge priority={priority} />
        <span className="text-sm text-muted-foreground">Antecedência: {advanceText}</span>
      </div>
    );
  } else if (nothingConfigured && !pending) {
    content = <span className="text-sm text-muted-foreground">A definir</span>;
  } else {
    // Partial/pending: label both fields explicitly so it's clear which one
    // is still missing, matching the pending example.
    content = (
      <div className="flex flex-col gap-1">
        {pending ? (
          <span className="flex items-center gap-1 text-sm font-medium text-amber-600 dark:text-amber-500">
            <TriangleAlert className="size-3.5 shrink-0" aria-hidden="true" />
            Configuração pendente
          </span>
        ) : null}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="text-sm text-muted-foreground">Prioridade:</span>
          {priority ? <PriorityBadge priority={priority} /> : <span className="text-sm text-muted-foreground">A definir</span>}
          <span className="text-sm text-muted-foreground">· Antecedência: {advanceText}</span>
        </div>
      </div>
    );
  }

  if (!clickable) return content;

  return (
    <button type="button" onClick={() => onConfigure(row)} className="text-left underline-offset-2 hover:underline">
      {content}
    </button>
  );
}
