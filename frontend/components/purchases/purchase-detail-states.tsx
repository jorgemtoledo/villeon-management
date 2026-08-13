import Link from "next/link";
import { ReceiptText, RefreshCw, TriangleAlert } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

export function PurchaseDetailLoadingState() {
  return (
    <div className="flex flex-col gap-4">
      <Skeleton className="h-32 w-full rounded-lg" />
      <Skeleton className="h-48 w-full rounded-lg" />
    </div>
  );
}

export function PurchaseNotFoundState() {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-dashed border-border py-16 text-center">
      <ReceiptText className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Compra não encontrada</p>
      <Button variant="outline" className="mt-1 h-11 md:h-9" nativeButton={false} render={<Link href="/compras" />}>
        Voltar para compras
      </Button>
    </div>
  );
}

// Shared by /compras/nova and /compras/:id/editar — same permission
// (canManagePurchases), same message, only the "back" link target differs.
export function PurchaseFormForbiddenState({ backHref = "/compras" }: { backHref?: string }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-dashed border-border py-16 text-center">
      <ReceiptText className="size-8 text-muted-foreground" aria-hidden="true" />
      <p className="font-medium text-foreground">Área restrita</p>
      <p className="text-sm text-muted-foreground">Você não tem permissão para gerenciar compras.</p>
      <Button variant="outline" className="mt-1 h-11 md:h-9" nativeButton={false} render={<Link href={backHref} />}>
        Voltar
      </Button>
    </div>
  );
}

export function PurchaseDetailErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-destructive/30 bg-destructive/5 py-16 text-center">
      <TriangleAlert className="size-8 text-destructive" aria-hidden="true" />
      <p className="font-medium text-foreground">Não foi possível carregar a compra</p>
      <p className="text-sm text-muted-foreground">Verifique sua conexão e tente novamente.</p>
      <Button type="button" variant="outline" onClick={onRetry} className="mt-1 h-11 md:h-9">
        <RefreshCw className="size-4" />
        Tentar novamente
      </Button>
    </div>
  );
}
