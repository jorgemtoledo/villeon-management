import { PackageSearch, RefreshCw, TriangleAlert, Warehouse } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function StockLoadingState() {
  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: 8 }).map((_, index) => (
        <Skeleton key={index} className="h-14 w-full rounded-lg" />
      ))}
    </div>
  );
}

export function StockEmptyState({ filtered = false }: { filtered?: boolean }) {
  return (
    <div className="flex flex-col items-center gap-2 rounded-lg border border-dashed border-border py-16 text-center">
      <PackageSearch className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">
        {filtered ? "Nenhum produto com esse status neste setor" : "Nenhum produto neste setor"}
      </p>
    </div>
  );
}

export function StockErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-destructive/30 bg-destructive/5 py-16 text-center">
      <TriangleAlert className="size-8 text-destructive" aria-hidden="true" />
      <p className="font-medium text-foreground">Não foi possível carregar o estoque</p>
      <p className="text-sm text-muted-foreground">Verifique sua conexão e tente novamente.</p>
      <Button type="button" variant="outline" onClick={onRetry} className="mt-1 h-11 md:h-9">
        <RefreshCw className="size-4" />
        Tentar novamente
      </Button>
    </div>
  );
}

// Distinct from ProductsEmptyState-style "no results": this means the user
// has zero sectors AND no all_sectors flag — a permission gap, not a filter
// that just came up empty (see lib/auth/permissions#allowedSectors).
export function StockNoSectorState() {
  return (
    <div className="flex flex-col items-center gap-2 rounded-lg border border-dashed border-border py-16 text-center">
      <Warehouse className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Você não tem acesso a nenhum setor de estoque</p>
      <p className="text-sm text-muted-foreground">Fale com um administrador para liberar seu acesso.</p>
    </div>
  );
}
