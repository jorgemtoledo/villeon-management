"use client";

import { useState } from "react";
import { toast } from "sonner";

import { useProductSuppliers } from "@/hooks/use-product-suppliers";
import {
  useCreateProductSupplier,
  useDeleteProductSupplier,
  usePreferProductSupplier,
} from "@/hooks/use-product-supplier-mutations";
import { ApiError } from "@/lib/api/client";
import { SupplierCombobox, type SupplierOption } from "@/components/purchases/supplier-combobox";
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
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Field, FieldContent, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import type { Product } from "@/types/product";
import type { ProductSupplierLink } from "@/types/product-supplier";

interface ProductSuppliersSectionProps {
  product: Product;
  canManage: boolean;
}

// Structural product data (Bloco 6I.1): principal + alternate suppliers.
// Rendered for every role that can open the sheet — read-only for
// manager/operator (no add/remove/prefer actions), matching the same
// admin-vs-everyone split as the rest of this sheet.
export function ProductSuppliersSection({ product, canManage }: ProductSuppliersSectionProps) {
  const { data: links, isPending, isError, refetch } = useProductSuppliers(product.id);
  const [addingOpen, setAddingOpen] = useState(false);

  return (
    <Card size="sm" className="mt-4">
      <CardHeader>
        <CardTitle>Fornecedores</CardTitle>
        <CardDescription>
          Fornecedor principal e fornecedores alternativos usados na compra deste produto.
        </CardDescription>
      </CardHeader>

      <CardContent className="flex flex-col gap-4">
        {isPending ? (
          <div className="flex flex-col gap-2">
            <Skeleton className="h-14 w-full" />
            <Skeleton className="h-14 w-full" />
          </div>
        ) : isError ? (
          <Alert variant="destructive">
            <AlertDescription>
              Não foi possível carregar os fornecedores deste produto.{" "}
              <button type="button" className="underline" onClick={() => refetch()}>
                Tentar novamente
              </button>
            </AlertDescription>
          </Alert>
        ) : (
          <>
            {links && links.length > 0 ? (
              <ul className="flex flex-col gap-2">
                {links.map((link) => (
                  <ProductSupplierRow key={link.id} link={link} productId={product.id} canManage={canManage} />
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted-foreground">Nenhum fornecedor vinculado a este produto.</p>
            )}

            {canManage ? (
              addingOpen ? (
                <AddProductSupplierForm
                  productId={product.id}
                  existingSupplierIds={(links ?? []).map((link) => link.supplier.id)}
                  onDone={() => setAddingOpen(false)}
                />
              ) : (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-11 self-start md:h-9"
                  onClick={() => setAddingOpen(true)}
                >
                  Adicionar fornecedor
                </Button>
              )
            ) : null}
          </>
        )}
      </CardContent>
    </Card>
  );
}

function ProductSupplierRow({
  link,
  productId,
  canManage,
}: {
  link: ProductSupplierLink;
  productId: number;
  canManage: boolean;
}) {
  const preferMutation = usePreferProductSupplier(productId);
  const deleteMutation = useDeleteProductSupplier(productId);

  function errorMessage(error: unknown, fallback: string) {
    return error instanceof ApiError ? error.message : fallback;
  }

  function handlePrefer() {
    preferMutation.mutate(link.id, {
      onSuccess: () => toast.success(`"${link.supplier.name}" agora é o fornecedor principal.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível definir o fornecedor principal.")),
    });
  }

  function handleRemove() {
    deleteMutation.mutate(link.id, {
      onSuccess: () => toast.success(`"${link.supplier.name}" foi removido dos fornecedores do produto.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível remover o fornecedor.")),
    });
  }

  return (
    <li className="flex flex-col gap-2 rounded-md border border-border p-3 sm:flex-row sm:items-start sm:justify-between">
      <div className="min-w-0">
        <div className="flex flex-wrap items-center gap-2">
          <span className="font-medium text-foreground">{link.supplier.name}</span>
          {link.preferred ? <Badge>Principal</Badge> : null}
        </div>
        {link.supplier_product_code ? (
          <p className="text-xs text-muted-foreground">Código no fornecedor: {link.supplier_product_code}</p>
        ) : null}
        {link.notes ? <p className="text-xs text-muted-foreground">{link.notes}</p> : null}
      </div>

      {canManage ? (
        <div className="flex shrink-0 gap-2">
          {!link.preferred ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="h-11 md:h-9"
              disabled={preferMutation.isPending}
              onClick={handlePrefer}
            >
              {preferMutation.isPending ? "Definindo..." : "Definir como principal"}
            </Button>
          ) : null}

          <AlertDialog>
            <AlertDialogTrigger
              render={
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-11 md:h-9"
                  disabled={deleteMutation.isPending}
                />
              }
            >
              {deleteMutation.isPending ? "Removendo..." : "Remover"}
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Remover este fornecedor?</AlertDialogTitle>
                <AlertDialogDescription>
                  &ldquo;{link.supplier.name}&rdquo; deixará de estar vinculado a este produto.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                <AlertDialogAction onClick={handleRemove}>Remover</AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      ) : null}
    </li>
  );
}

function AddProductSupplierForm({
  productId,
  existingSupplierIds,
  onDone,
}: {
  productId: number;
  existingSupplierIds: number[];
  onDone: () => void;
}) {
  const [supplier, setSupplier] = useState<SupplierOption | null>(null);
  const [preferred, setPreferred] = useState(false);
  const [supplierProductCode, setSupplierProductCode] = useState("");
  const [notes, setNotes] = useState("");
  const mutation = useCreateProductSupplier(productId);

  const alreadyLinked = supplier !== null && existingSupplierIds.includes(supplier.id);

  function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!supplier || alreadyLinked) return;

    mutation.mutate(
      {
        supplier_id: supplier.id,
        preferred,
        supplier_product_code: supplierProductCode || null,
        notes: notes || null,
      },
      {
        onSuccess: () => {
          toast.success(`"${supplier.name}" foi adicionado aos fornecedores do produto.`);
          onDone();
        },
        onError: (error) => {
          toast.error(error instanceof ApiError ? error.message : "Não foi possível adicionar o fornecedor.");
        },
      },
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3 rounded-md border border-border p-3">
      <Field>
        <FieldLabel htmlFor="product-supplier-combobox">Fornecedor</FieldLabel>
        <FieldContent>
          <SupplierCombobox id="product-supplier-combobox" value={supplier} onChange={setSupplier} />
          {alreadyLinked ? (
            <p className="text-xs text-destructive">Este fornecedor já está vinculado ao produto.</p>
          ) : null}
        </FieldContent>
      </Field>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <Field>
          <FieldLabel htmlFor="product-supplier-code">Código no fornecedor (opcional)</FieldLabel>
          <FieldContent>
            <Input
              id="product-supplier-code"
              value={supplierProductCode}
              onChange={(event) => setSupplierProductCode(event.target.value)}
            />
          </FieldContent>
        </Field>

        <Field>
          <FieldLabel htmlFor="product-supplier-notes">Observações (opcional)</FieldLabel>
          <FieldContent>
            <Input id="product-supplier-notes" value={notes} onChange={(event) => setNotes(event.target.value)} />
          </FieldContent>
        </Field>
      </div>

      <Label htmlFor="product-supplier-preferred" className="flex w-fit items-center gap-2 font-normal">
        <Checkbox
          id="product-supplier-preferred"
          checked={preferred}
          onCheckedChange={(checked) => setPreferred(checked === true)}
        />
        Definir como fornecedor principal
      </Label>

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" size="sm" className="h-11 md:h-9" onClick={onDone}>
          Cancelar
        </Button>
        <Button type="submit" size="sm" className="h-11 md:h-9" disabled={!supplier || alreadyLinked || mutation.isPending}>
          {mutation.isPending ? "Adicionando..." : "Adicionar"}
        </Button>
      </div>
    </form>
  );
}
