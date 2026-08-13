import { PackageSearch, RefreshCw, TriangleAlert } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function SupplierProductsLoadingState() {
  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: 4 }).map((_, index) => (
        <Skeleton key={index} className="h-14 w-full rounded-lg" />
      ))}
    </div>
  );
}

// Expected state for all 101 real suppliers today — ProductSupplier.count is
// 0 in the database, so this is not an edge case, it's the common case.
export function SupplierProductsEmptyState() {
  return (
    <div className="flex flex-col items-center gap-2 rounded-lg border border-dashed border-border py-12 text-center">
      <PackageSearch className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Nenhum produto vinculado a este fornecedor.</p>
    </div>
  );
}

export function SupplierProductsErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-destructive/30 bg-destructive/5 py-12 text-center">
      <TriangleAlert className="size-8 text-destructive" aria-hidden="true" />
      <p className="font-medium text-foreground">Não foi possível carregar os produtos vinculados</p>
      <Button type="button" variant="outline" onClick={onRetry} className="mt-1 h-11 md:h-9">
        <RefreshCw className="size-4" />
        Tentar novamente
      </Button>
    </div>
  );
}
