import { ReceiptText, RefreshCw, TriangleAlert } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function PurchasesLoadingState() {
  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: 8 }).map((_, index) => (
        <Skeleton key={index} className="h-14 w-full rounded-lg" />
      ))}
    </div>
  );
}

export function PurchasesEmptyState() {
  return (
    <div className="flex flex-col items-center gap-2 rounded-lg border border-dashed border-border py-16 text-center">
      <ReceiptText className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Nenhuma compra encontrada</p>
      <p className="text-sm text-muted-foreground">Ajuste a busca ou o período e tente novamente.</p>
    </div>
  );
}

export function PurchasesErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-destructive/30 bg-destructive/5 py-16 text-center">
      <TriangleAlert className="size-8 text-destructive" aria-hidden="true" />
      <p className="font-medium text-foreground">Não foi possível carregar as compras</p>
      <p className="text-sm text-muted-foreground">Verifique sua conexão e tente novamente.</p>
      <Button type="button" variant="outline" onClick={onRetry} className="mt-1 h-11 md:h-9">
        <RefreshCw className="size-4" />
        Tentar novamente
      </Button>
    </div>
  );
}
