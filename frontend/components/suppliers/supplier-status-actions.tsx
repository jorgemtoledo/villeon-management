"use client";

import { toast } from "sonner";

import { useActivateSupplier, useDeactivateSupplier } from "@/hooks/use-supplier-mutations";
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
import type { Supplier } from "@/types/supplier";

// Used both in the suppliers list (table row / mobile card) and in the
// supplier detail page — same actions, same admin-only visibility (callers
// decide whether to render this at all).
export function SupplierStatusActions({ supplier, onEdit }: { supplier: Supplier; onEdit: () => void }) {
  const activateMutation = useActivateSupplier();
  const deactivateMutation = useDeactivateSupplier();

  function errorMessage(error: unknown, fallback: string) {
    return error instanceof ApiError ? error.message : fallback;
  }

  function handleActivate() {
    activateMutation.mutate(supplier.id, {
      onSuccess: () => toast.success(`"${supplier.name}" foi ativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível ativar o fornecedor.")),
    });
  }

  function handleDeactivate() {
    deactivateMutation.mutate(supplier.id, {
      onSuccess: () => toast.success(`"${supplier.name}" foi desativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível desativar o fornecedor.")),
    });
  }

  return (
    <div className="flex gap-2">
      <Button type="button" variant="outline" size="sm" className="h-11 md:h-9" onClick={onEdit}>
        Editar
      </Button>

      {supplier.active ? (
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
              <AlertDialogTitle>Desativar este fornecedor?</AlertDialogTitle>
              <AlertDialogDescription>
                &ldquo;{supplier.name}&rdquo; continuará cadastrado, mas ficará inativo até ser reativado.
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
