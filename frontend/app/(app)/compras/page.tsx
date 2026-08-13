"use client";

import { useState } from "react";
import Link from "next/link";
import { Plus } from "lucide-react";

import { usePurchases } from "@/hooks/use-purchases";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { useAuth } from "@/hooks/use-auth";
import { canManagePurchases } from "@/lib/auth/permissions";
import { Button } from "@/components/ui/button";
import { Pagination } from "@/components/shared/pagination";
import { PurchasesFilters } from "@/components/purchases/purchases-filters";
import { PurchasesTable } from "@/components/purchases/purchases-table";
import { PurchasesCards } from "@/components/purchases/purchases-cards";
import {
  PurchasesEmptyState,
  PurchasesErrorState,
  PurchasesLoadingState,
} from "@/components/purchases/purchases-states";

const PER_PAGE = 25;

export default function ComprasPage() {
  const { user } = useAuth();
  const canCreate = canManagePurchases(user);

  const [search, setSearch] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [page, setPage] = useState(1);
  const debouncedSearch = useDebouncedValue(search, 400);

  // Same render-time adjustment pattern as /produtos and /fornecedores: a
  // filter change resets pagination to page 1 without ever painting a stale
  // page first.
  const [appliedFilters, setAppliedFilters] = useState({ search: debouncedSearch, dateFrom, dateTo });
  if (
    appliedFilters.search !== debouncedSearch ||
    appliedFilters.dateFrom !== dateFrom ||
    appliedFilters.dateTo !== dateTo
  ) {
    setAppliedFilters({ search: debouncedSearch, dateFrom, dateTo });
    setPage(1);
  }

  const { data, isPending, isError, isPlaceholderData, refetch } = usePurchases({
    q: debouncedSearch || undefined,
    dateFrom: dateFrom || undefined,
    dateTo: dateTo || undefined,
    page,
    perPage: PER_PAGE,
    sort: "purchased_at",
    order: "desc",
  });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Compras</h1>
          <p className="text-sm text-muted-foreground">
            Histórico de compras — busca, filtro por período e paginação.
          </p>
        </div>
        {canCreate ? (
          <Button type="button" className="h-11 md:h-9" nativeButton={false} render={<Link href="/compras/nova" />}>
            <Plus className="size-4" />
            Nova compra
          </Button>
        ) : null}
      </div>

      <PurchasesFilters
        search={search}
        onSearchChange={setSearch}
        dateFrom={dateFrom}
        onDateFromChange={setDateFrom}
        dateTo={dateTo}
        onDateToChange={setDateTo}
      />

      {isPending ? <PurchasesLoadingState /> : null}

      {isError ? <PurchasesErrorState onRetry={() => refetch()} /> : null}

      {!isPending && !isError && data ? (
        data.data.length === 0 ? (
          <PurchasesEmptyState />
        ) : (
          <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
            <PurchasesTable purchases={data.data} />
            <PurchasesCards purchases={data.data} />
            <Pagination meta={data.meta} onPageChange={setPage} itemLabel="compras" />
          </div>
        )
      ) : null}
    </div>
  );
}
