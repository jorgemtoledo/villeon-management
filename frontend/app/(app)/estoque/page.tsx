"use client";

import { useState } from "react";

import { useAuth } from "@/hooks/use-auth";
import { allowedSectors, canViewStockHistory } from "@/lib/auth/permissions";
import { useProductStocks } from "@/hooks/use-product-stocks";
import { Pagination } from "@/components/shared/pagination";
import { StockSectorSelect } from "@/components/stock/stock-sector-select";
import { StockStatusSelect } from "@/components/stock/stock-status-select";
import { StockTable } from "@/components/stock/stock-table";
import { StockCards } from "@/components/stock/stock-cards";
import { StockCountSheet } from "@/components/stock/stock-count-sheet";
import { StockHistorySheet } from "@/components/stock/stock-history-sheet";
import {
  StockEmptyState,
  StockErrorState,
  StockLoadingState,
  StockNoSectorState,
} from "@/components/stock/stock-states";
import type { ProductStock, StockStatus } from "@/types/product-stock";

const PER_PAGE = 25;

export default function EstoquePage() {
  const { user } = useAuth();
  const sectors = allowedSectors(user);
  const canViewHistory = canViewStockHistory(user);

  const [ sectorId, setSectorId ] = useState<number | undefined>(sectors[0]?.id);
  const [ status, setStatus ] = useState<StockStatus | undefined>(undefined);
  const [ page, setPage ] = useState(1);
  const [ countTarget, setCountTarget ] = useState<ProductStock | undefined>(undefined);
  const [ historyTarget, setHistoryTarget ] = useState<ProductStock | undefined>(undefined);
  // Bloco 6G Parte 4.1: "Configuração de compra" opens the same Sheet but
  // straight to the priority step (row is already status "comprar" — that's
  // the only time this column is clickable — so there's nothing to count).
  const [ openToPriority, setOpenToPriority ] = useState(false);

  const { data, isPending, isError, isPlaceholderData, refetch } = useProductStocks({
    sectorId,
    status,
    page,
    perPage: PER_PAGE,
  });

  function handleSectorChange(id: number) {
    setSectorId(id);
    setPage(1);
  }

  function handleStatusChange(next: StockStatus | undefined) {
    setStatus(next);
    setPage(1);
  }

  function handleCount(row: ProductStock) {
    setOpenToPriority(false);
    setCountTarget(row);
  }

  function handleConfigurePriority(row: ProductStock) {
    setOpenToPriority(true);
    setCountTarget(row);
  }

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Estoque</h1>
        <p className="text-sm text-muted-foreground">
          Contagem por setor — estoque atual, mínimo, ideal, reposição e status de compra.
        </p>
      </div>

      {sectors.length === 0 ? (
        <StockNoSectorState />
      ) : (
        <>
          <div className="flex flex-col gap-3 md:flex-row">
            <StockSectorSelect sectors={sectors} value={sectorId} onChange={handleSectorChange} />
            <StockStatusSelect value={status} onChange={handleStatusChange} />
          </div>

          {isPending ? <StockLoadingState /> : null}

          {isError ? <StockErrorState onRetry={() => refetch()} /> : null}

          {!isPending && !isError && data ? (
            data.data.length === 0 ? (
              <StockEmptyState filtered={status !== undefined} />
            ) : (
              <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
                <StockTable
                  rows={data.data}
                  onCount={handleCount}
                  onConfigurePriority={handleConfigurePriority}
                  onViewHistory={canViewHistory ? setHistoryTarget : undefined}
                />
                <StockCards
                  rows={data.data}
                  onCount={handleCount}
                  onConfigurePriority={handleConfigurePriority}
                  onViewHistory={canViewHistory ? setHistoryTarget : undefined}
                />
                <Pagination meta={data.meta} onPageChange={setPage} itemLabel="produtos" />
              </div>
            )
          ) : null}
        </>
      )}

      <StockCountSheet
        open={countTarget !== undefined}
        onOpenChange={(open) => {
          if (!open) {
            setCountTarget(undefined);
            setOpenToPriority(false);
          }
        }}
        row={countTarget}
        openToPriority={openToPriority}
      />

      <StockHistorySheet
        open={historyTarget !== undefined}
        onOpenChange={(open) => {
          if (!open) setHistoryTarget(undefined);
        }}
        product={historyTarget?.product}
      />
    </div>
  );
}
