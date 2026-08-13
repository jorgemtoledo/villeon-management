"use client";

import { toast } from "sonner";

import { useCreateProduct, useUpdateProduct } from "@/hooks/use-product-mutations";
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
import { ProductForm } from "@/components/products/product-form";
import { ProductStockConfigForm } from "@/components/products/product-stock-config-form";
import type { Product, ProductInput } from "@/types/product";

const FORM_ID = "product-form";

interface ProductFormSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  // undefined = create mode, a Product = edit mode.
  product?: Product;
}

export function ProductFormSheet({ open, onOpenChange, product }: ProductFormSheetProps) {
  const createMutation = useCreateProduct();
  // Hooks can't be called conditionally — id is only used by the mutation
  // fn when the form actually submits in edit mode, so a placeholder id
  // while creating is harmless (never sent anywhere).
  const updateMutation = useUpdateProduct(product?.id ?? -1);

  const mutation = product ? updateMutation : createMutation;
  const isEditing = !!product;

  function handleSubmit(input: ProductInput) {
    mutation.mutate(input, {
      onSuccess: () => {
        toast.success(isEditing ? "Produto atualizado com sucesso." : "Produto criado com sucesso.");
        onOpenChange(false);
      },
    });
  }

  const error = mutation.error;
  const errorMessage = error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar o produto." : null;
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
          <SheetTitle>{isEditing ? "Editar produto" : "Novo produto"}</SheetTitle>
          <SheetDescription>
            {isEditing
              ? "Altere os dados do produto e salve para aplicar as mudanças."
              : "Preencha os dados do novo produto do catálogo."}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto px-4 py-1">
          <ProductForm
            key={open ? (product?.id ?? "new") : "closed"}
            formId={FORM_ID}
            product={product}
            onSubmit={handleSubmit}
            errorMessage={errorMessage}
            errorDetails={errorDetails}
          />

          {/* Stock config is a separate resource/endpoint (Bloco 6G Parte 2)
              from the Product fields above — only meaningful once the
              product exists, so it's create-mode-only absent, with its own
              independent save action. */}
          {product ? <ProductStockConfigForm product={product} /> : null}
        </div>

        <SheetFooter className="flex-row justify-end gap-2">
          <Button type="button" variant="outline" className="h-11 md:h-9" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button type="submit" form={FORM_ID} disabled={mutation.isPending} className="h-11 md:h-9">
            {mutation.isPending ? "Salvando..." : isEditing ? "Salvar alterações" : "Criar produto"}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
