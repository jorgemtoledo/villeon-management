"use client";

import { useState } from "react";
import { Plus } from "lucide-react";

import { useProducts } from "@/hooks/use-products";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { useAuth } from "@/hooks/use-auth";
import { canManageProducts } from "@/lib/auth/permissions";
import { Button } from "@/components/ui/button";
import { Pagination } from "@/components/shared/pagination";
import { ProductsFilters, type StatusFilter } from "@/components/products/products-filters";
import { ProductsTable } from "@/components/products/products-table";
import { ProductsCards } from "@/components/products/products-cards";
import { ProductFormSheet } from "@/components/products/product-form-sheet";
import {
  ProductsEmptyState,
  ProductsErrorState,
  ProductsLoadingState,
} from "@/components/products/products-states";
import type { Product } from "@/types/product";

const PER_PAGE = 25;

// undefined = Sheet closed; "new" = create mode; a Product = edit mode.
type SheetTarget = Product | "new" | undefined;

export default function ProdutosPage() {
  const { user } = useAuth();
  const canManage = canManageProducts(user);

  const [search, setSearch] = useState("");
  const [sectorId, setSectorId] = useState<number | undefined>(undefined);
  const [status, setStatus] = useState<StatusFilter>("all");
  const [page, setPage] = useState(1);
  const [sheetTarget, setSheetTarget] = useState<SheetTarget>(undefined);
  const debouncedSearch = useDebouncedValue(search, 400);

  // Any filter change restarts pagination at page 1 — staying on page 6 of
  // a filter that now only has 2 pages would just show an empty result.
  // Adjusted during render (React's documented pattern for this), not in an
  // effect, so the stale page never actually paints before the reset.
  const [appliedFilters, setAppliedFilters] = useState({ search: debouncedSearch, sectorId, status });
  if (
    appliedFilters.search !== debouncedSearch ||
    appliedFilters.sectorId !== sectorId ||
    appliedFilters.status !== status
  ) {
    setAppliedFilters({ search: debouncedSearch, sectorId, status });
    setPage(1);
  }

  const { data, isPending, isError, isPlaceholderData, refetch } = useProducts({
    q: debouncedSearch || undefined,
    sectorId,
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
          <h1 className="text-xl font-semibold text-foreground">Catálogo de produtos</h1>
          <p className="text-sm text-muted-foreground">
            Consulta do Catálogo Mestre — busca, filtro por setor/status e paginação.
          </p>
        </div>
        {canManage ? (
          <Button type="button" className="h-11 md:h-9" onClick={() => setSheetTarget("new")}>
            <Plus className="size-4" />
            Novo produto
          </Button>
        ) : null}
      </div>

      <ProductsFilters
        search={search}
        onSearchChange={setSearch}
        sectorId={sectorId}
        onSectorChange={setSectorId}
        status={status}
        onStatusChange={setStatus}
      />

      {isPending ? <ProductsLoadingState /> : null}

      {isError ? <ProductsErrorState onRetry={() => refetch()} /> : null}

      {!isPending && !isError && data ? (
        data.data.length === 0 ? (
          <ProductsEmptyState />
        ) : (
          <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
            <ProductsTable products={data.data} canManage={canManage} onEdit={setSheetTarget} />
            <ProductsCards products={data.data} canManage={canManage} onEdit={setSheetTarget} />
            <Pagination meta={data.meta} onPageChange={setPage} itemLabel="produtos" />
          </div>
        )
      ) : null}

      {canManage ? (
        <ProductFormSheet
          open={sheetTarget !== undefined}
          onOpenChange={(open) => {
            if (!open) setSheetTarget(undefined);
          }}
          product={sheetTarget === "new" ? undefined : sheetTarget}
        />
      ) : null}
    </div>
  );
}
