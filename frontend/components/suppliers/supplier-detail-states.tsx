import Link from "next/link";
import { RefreshCw, TriangleAlert, UserRoundX } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function SupplierDetailLoadingState() {
  return (
    <div className="flex flex-col gap-4">
      <Skeleton className="h-32 w-full rounded-lg" />
      <Skeleton className="h-48 w-full rounded-lg" />
    </div>
  );
}

export function SupplierNotFoundState() {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-dashed border-border py-16 text-center">
      <UserRoundX className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Fornecedor não encontrado</p>
      {/* nativeButton={false}: this Button intentionally renders as an <a>
          (via `render`), not a <button> — without the flag Base UI warns
          that native button semantics (forms/accessibility) are lost. */}
      <Button
        variant="outline"
        className="mt-1 h-11 md:h-9"
        nativeButton={false}
        render={<Link href="/fornecedores" />}
      >
        Voltar para fornecedores
      </Button>
    </div>
  );
}

export function SupplierDetailErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-destructive/30 bg-destructive/5 py-16 text-center">
      <TriangleAlert className="size-8 text-destructive" aria-hidden="true" />
      <p className="font-medium text-foreground">Não foi possível carregar o fornecedor</p>
      <p className="text-sm text-muted-foreground">Verifique sua conexão e tente novamente.</p>
      <Button type="button" variant="outline" onClick={onRetry} className="mt-1 h-11 md:h-9">
        <RefreshCw className="size-4" />
        Tentar novamente
      </Button>
    </div>
  );
}
