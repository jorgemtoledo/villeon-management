"use client";

import { toast } from "sonner";

import { useCreateSupplier, useUpdateSupplier } from "@/hooks/use-supplier-mutations";
import { ApiError } from "@/lib/api/client";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { SupplierForm } from "@/components/suppliers/supplier-form";
import type { Supplier, SupplierInput } from "@/types/supplier";

const FORM_ID = "supplier-form";

interface SupplierFormSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  // undefined = create mode, a Supplier = edit mode.
  supplier?: Supplier;
}

export function SupplierFormSheet({ open, onOpenChange, supplier }: SupplierFormSheetProps) {
  const createMutation = useCreateSupplier();
  // Hooks can't be called conditionally — id is only used by the mutation
  // fn when the form actually submits in edit mode, so a placeholder id
  // while creating is harmless (never sent anywhere).
  const updateMutation = useUpdateSupplier(supplier?.id ?? -1);

  const mutation = supplier ? updateMutation : createMutation;
  const isEditing = !!supplier;

  function handleSubmit(input: SupplierInput) {
    mutation.mutate(input, {
      onSuccess: () => {
        toast.success(isEditing ? "Fornecedor atualizado com sucesso." : "Fornecedor criado com sucesso.");
        onOpenChange(false);
      },
    });
  }

  const error = mutation.error;
  const errorMessage = error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar o fornecedor." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <Sheet
      open={open}
      onOpenChange={(next) => {
        if (!next) mutation.reset();
        onOpenChange(next);
      }}
    >
      <SheetContent side="right" className="w-full sm:max-w-lg">
        <SheetHeader>
          <SheetTitle>{isEditing ? "Editar fornecedor" : "Novo fornecedor"}</SheetTitle>
          <SheetDescription>
            {isEditing
              ? "Altere os dados do fornecedor e salve para aplicar as mudanças."
              : "Preencha os dados do novo fornecedor."}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto px-4 py-1">
          <SupplierForm
            key={open ? (supplier?.id ?? "new") : "closed"}
            formId={FORM_ID}
            supplier={supplier}
            onSubmit={handleSubmit}
            errorMessage={errorMessage}
            errorDetails={errorDetails}
          />
        </div>

        <SheetFooter className="flex-row justify-end gap-2">
          <Button type="button" variant="outline" className="h-11 md:h-9" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button type="submit" form={FORM_ID} disabled={mutation.isPending} className="h-11 md:h-9">
            {mutation.isPending ? "Salvando..." : isEditing ? "Salvar alterações" : "Criar fornecedor"}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
