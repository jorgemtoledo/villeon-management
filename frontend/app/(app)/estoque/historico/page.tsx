"use client";

import { useState } from "react";

import { useAuth } from "@/hooks/use-auth";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { useStockAuditEntries } from "@/hooks/use-stock-audit-entries";
import { canViewStockHistory } from "@/lib/auth/permissions";
import { Pagination } from "@/components/shared/pagination";
import { StockHistoryFilters, type FieldFilter } from "@/components/stock/stock-history-filters";
import { StockHistoryTable } from "@/components/stock/stock-history-table";
import { StockHistoryCards } from "@/components/stock/stock-history-cards";
import {
  StockHistoryEmptyState,
  StockHistoryErrorState,
  StockHistoryForbiddenState,
  StockHistoryLoadingState,
} from "@/components/stock/stock-history-states";

const PER_PAGE = 25;

export default function HistoricoEstoquePage() {
  const { user } = useAuth();
  const canView = canViewStockHistory(user);

  const [search, setSearch] = useState("");
  const [userId, setUserId] = useState<number | undefined>(undefined);
  const [field, setField] = useState<FieldFilter>("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [page, setPage] = useState(1);
  const debouncedSearch = useDebouncedValue(search, 400);

  // Same "reset to page 1 on any filter change" pattern as /produtos and
  // /compras — adjusted during render, not in an effect.
  const [appliedFilters, setAppliedFilters] = useState({
    search: debouncedSearch,
    userId,
    field,
    dateFrom,
    dateTo,
  });
  if (
    appliedFilters.search !== debouncedSearch ||
    appliedFilters.userId !== userId ||
    appliedFilters.field !== field ||
    appliedFilters.dateFrom !== dateFrom ||
    appliedFilters.dateTo !== dateTo
  ) {
    setAppliedFilters({ search: debouncedSearch, userId, field, dateFrom, dateTo });
    setPage(1);
  }

  // Page-level guard: an operator who navigates here directly never even
  // triggers the request (enabled: canView) — the real protection is still
  // the backend's 403, this just avoids a pointless round trip and shows a
  // clear message instead of an error state.
  const { data, isPending, isError, isPlaceholderData, refetch } = useStockAuditEntries(
    {
      q: debouncedSearch || undefined,
      userId,
      field: field === "all" ? undefined : field,
      dateFrom: dateFrom || undefined,
      dateTo: dateTo || undefined,
      page,
      perPage: PER_PAGE,
    },
    { enabled: canView },
  );

  if (!canView) {
    return <StockHistoryForbiddenState />;
  }

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Histórico de estoque</h1>
        <p className="text-sm text-muted-foreground">
          Auditoria das alterações de estoque atual, prioridade e antecedência — mais recente primeiro.
        </p>
      </div>

      <StockHistoryFilters
        search={search}
        onSearchChange={setSearch}
        userId={userId}
        onUserChange={setUserId}
        field={field}
        onFieldChange={setField}
        dateFrom={dateFrom}
        onDateFromChange={setDateFrom}
        dateTo={dateTo}
        onDateToChange={setDateTo}
      />

      {isPending ? <StockHistoryLoadingState /> : null}

      {isError ? <StockHistoryErrorState onRetry={() => refetch()} /> : null}

      {!isPending && !isError && data ? (
        data.data.length === 0 ? (
          <StockHistoryEmptyState />
        ) : (
          <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
            <StockHistoryTable entries={data.data} />
            <StockHistoryCards entries={data.data} />
            <Pagination meta={data.meta} onPageChange={setPage} itemLabel="alterações" />
          </div>
        )
      ) : null}
    </div>
  );
}
