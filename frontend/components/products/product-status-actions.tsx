"use client";

import { toast } from "sonner";

import { useActivateProduct, useDeactivateProduct } from "@/hooks/use-product-mutations";
import { ApiError } from "@/lib/api/client";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import type { Product } from "@/types/product";

// Used both in the desktop table row and the mobile card — same actions,
// same admin-only visibility (callers decide whether to render this at all).
export function ProductStatusActions({ product, onEdit }: { product: Product; onEdit: () => void }) {
  const activateMutation = useActivateProduct();
  const deactivateMutation = useDeactivateProduct();

  function errorMessage(error: unknown, fallback: string) {
    return error instanceof ApiError ? error.message : fallback;
  }

  function handleActivate() {
    activateMutation.mutate(product.id, {
      onSuccess: () => toast.success(`"${product.name}" foi ativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível ativar o produto.")),
    });
  }

  function handleDeactivate() {
    deactivateMutation.mutate(product.id, {
      onSuccess: () => toast.success(`"${product.name}" foi desativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível desativar o produto.")),
    });
  }

  return (
    <div className="flex gap-2">
      <Button type="button" variant="outline" size="sm" className="h-11 md:h-9" onClick={onEdit}>
        Editar
      </Button>

      {product.active ? (
        <AlertDialog>
          <AlertDialogTrigger
            render={
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-11 md:h-9"
                disabled={deactivateMutation.isPending}
              />
            }
          >
            {deactivateMutation.isPending ? "Desativando..." : "Desativar"}
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Desativar este produto?</AlertDialogTitle>
              <AlertDialogDescription>
                &ldquo;{product.name}&rdquo; continuará cadastrado, mas ficará inativo até ser reativado.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancelar</AlertDialogCancel>
              <AlertDialogAction onClick={handleDeactivate}>Desativar</AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      ) : (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="h-11 md:h-9"
          onClick={handleActivate}
          disabled={activateMutation.isPending}
        >
          {activateMutation.isPending ? "Ativando..." : "Ativar"}
        </Button>
      )}
    </div>
  );
}
