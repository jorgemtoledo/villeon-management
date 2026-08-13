"use client";

import { useState } from "react";
import { Plus } from "lucide-react";

import { useSuppliers } from "@/hooks/use-suppliers";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { useAuth } from "@/hooks/use-auth";
import { canManageSuppliers } from "@/lib/auth/permissions";
import { Button } from "@/components/ui/button";
import { Pagination } from "@/components/shared/pagination";
import { SuppliersFilters, type StatusFilter } from "@/components/suppliers/suppliers-filters";
import { SuppliersTable } from "@/components/suppliers/suppliers-table";
import { SuppliersCards } from "@/components/suppliers/suppliers-cards";
import { SupplierFormSheet } from "@/components/suppliers/supplier-form-sheet";
import {
  SuppliersEmptyState,
  SuppliersErrorState,
  SuppliersLoadingState,
} from "@/components/suppliers/suppliers-states";
import type { Supplier } from "@/types/supplier";

const PER_PAGE = 25;

// undefined = Sheet closed; "new" = create mode; a Supplier = edit mode.
type SheetTarget = Supplier | "new" | undefined;

export default function FornecedoresPage() {
  const { user } = useAuth();
  const canManage = canManageSuppliers(user);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [page, setPage] = useState(1);
  const [sheetTarget, setSheetTarget] = useState<SheetTarget>(undefined);
  const debouncedSearch = useDebouncedValue(search, 400);

  // Same render-time adjustment pattern as /produtos: a filter change resets
  // pagination to page 1 without ever painting a stale page first.
  const [appliedFilters, setAppliedFilters] = useState({ search: debouncedSearch, status });
  if (appliedFilters.search !== debouncedSearch || appliedFilters.status !== status) {
    setAppliedFilters({ search: debouncedSearch, status });
    setPage(1);
  }

  const { data, isPending, isError, isPlaceholderData, refetch } = useSuppliers({
    q: debouncedSearch || undefined,
    active: status === "all" ? undefined : status === "active",
    page,
    perPage: PER_PAGE,
    sort: "name",
    order: "asc",
  });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Fornecedores</h1>
          <p className="text-sm text-muted-foreground">Consulta de fornecedores — busca, filtro por status e paginação.</p>
        </div>
        {canManage ? (
          <Button type="button" className="h-11 md:h-9" onClick={() => setSheetTarget("new")}>
            <Plus className="size-4" />
            Novo fornecedor
          </Button>
        ) : null}
      </div>

      <SuppliersFilters search={search} onSearchChange={setSearch} status={status} onStatusChange={setStatus} />

      {isPending ? <SuppliersLoadingState /> : null}

      {isError ? <SuppliersErrorState onRetry={() => refetch()} /> : null}

      {!isPending && !isError && data ? (
        data.data.length === 0 ? (
          <SuppliersEmptyState />
        ) : (
          <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
            <SuppliersTable suppliers={data.data} canManage={canManage} onEdit={setSheetTarget} />
            <SuppliersCards suppliers={data.data} canManage={canManage} onEdit={setSheetTarget} />
            <Pagination meta={data.meta} onPageChange={setPage} itemLabel="fornecedores" />
          </div>
        )
      ) : null}

      {canManage ? (
        <SupplierFormSheet
          open={sheetTarget !== undefined}
          onOpenChange={(open) => {
            if (!open) setSheetTarget(undefined);
          }}
          supplier={sheetTarget === "new" ? undefined : sheetTarget}
        />
      ) : null}
    </div>
  );
}
