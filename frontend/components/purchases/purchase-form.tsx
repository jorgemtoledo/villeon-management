"use client";

import { useState } from "react";
import { Controller, useFieldArray, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Plus, Trash2 } from "lucide-react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field, FieldContent, FieldError, FieldLabel } from "@/components/ui/field";
import { SupplierCombobox, type SupplierOption } from "@/components/purchases/supplier-combobox";
import { ProductCombobox, type ProductOption } from "@/components/purchases/product-combobox";
import { formatCurrency } from "@/lib/format-currency";
import type { PurchaseDetail, PurchaseInput } from "@/types/purchase";

// Mirrors Api::V1::PurchasesController#purchase_params exactly (see
// Bloco 6H.1) — same required/optional split as the backend. quantity/
// unit_price min values match the model validations (quantity > 0,
// unit_price >= 0); total_amount is never a field here at all, since the
// backend always computes it and never accepts one from the client.
// quantity/unit_price go through `preprocess` so an empty input reads as
// "missing" (z.coerce.number({error}) below) rather than silently coercing
// "" -> 0 — which would otherwise slip past unit_price's own `min(0)` (0 is
// a legitimately valid price) and submit an unset field as R$0,00.
const requiredCoercedNumber = (message: string) =>
  z.preprocess((val) => (val === "" ? undefined : val), z.coerce.number({ error: message }));

const itemSchema = z.object({
  product_id: z.coerce.number({ error: "Selecione o produto." }).int().positive("Selecione o produto."),
  quantity: requiredCoercedNumber("Informe a quantidade.").pipe(
    z.number().positive("A quantidade deve ser maior que zero."),
  ),
  unit_price: requiredCoercedNumber("Informe o preço.").pipe(
    z.number().min(0, "O preço não pode ser negativo."),
  ),
});

const purchaseSchema = z.object({
  supplier_id: z.coerce.number({ error: "Selecione o fornecedor." }).int().positive("Selecione o fornecedor."),
  purchased_at: z.string().min(1, "Informe a data da compra."),
  invoice_number: z.string().optional(),
  items: z.array(itemSchema).min(1, "Adicione pelo menos um item."),
});

type PurchaseFormInput = z.input<typeof purchaseSchema>;
type PurchaseFormValues = z.output<typeof purchaseSchema>;

function todayIsoDate(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
}

function emptyItem(): PurchaseFormInput["items"][number] {
  return { product_id: undefined, quantity: undefined, unit_price: undefined };
}

interface PurchaseFormProps {
  formId: string;
  onSubmit: (input: PurchaseInput) => void;
  errorMessage?: string | null;
  errorDetails?: string[];
  // undefined = create mode. Present = edit mode — pre-fills every field,
  // including the comboboxes' display state, from the existing purchase.
  // Parent only ever mounts PurchaseForm once this data is loaded (see
  // /compras/[id]/editar), so a plain initial value (not a lazy `useState`
  // initializer or an effect+reset) is enough — it never changes mid-mount.
  purchase?: PurchaseDetail;
}

export function PurchaseForm({ formId, onSubmit, errorMessage, errorDetails, purchase }: PurchaseFormProps) {
  // Comboboxes are controlled by product_id/supplier_id (react-hook-form,
  // validated the same z.coerce.number way as every other *_id select in
  // the app — see product-form.tsx). The actual Supplier/Product objects
  // are kept in parallel local state only for display (the combobox's
  // input text) — they're never read back out for the submit payload.
  const [selectedSupplier, setSelectedSupplier] = useState<SupplierOption | null>(purchase?.supplier ?? null);
  const [selectedProducts, setSelectedProducts] = useState<(ProductOption | null)[]>(
    purchase ? purchase.items.map((item) => item.product) : [null],
  );

  const form = useForm<PurchaseFormInput, unknown, PurchaseFormValues>({
    resolver: zodResolver(purchaseSchema),
    defaultValues: purchase
      ? {
          supplier_id: purchase.supplier.id,
          // purchased_at is an ISO datetime string (UTC midnight, see
          // format-date.ts) — the first 10 chars are always its
          // YYYY-MM-DD, exactly what the date <Input> needs.
          purchased_at: purchase.purchased_at.slice(0, 10),
          invoice_number: purchase.invoice_number ?? "",
          items: purchase.items.map((item) => ({
            product_id: item.product.id,
            quantity: Number(item.quantity),
            unit_price: Number(item.unit_price),
          })),
        }
      : {
          supplier_id: undefined,
          purchased_at: todayIsoDate(),
          invoice_number: "",
          items: [emptyItem()],
        },
  });

  const { fields, append, remove } = useFieldArray({ control: form.control, name: "items" });
  const watchedItems = form.watch("items");

  const total = watchedItems.reduce((sum, item) => {
    return sum + (Number(item.quantity) || 0) * (Number(item.unit_price) || 0);
  }, 0);

  function addItem() {
    append(emptyItem());
    setSelectedProducts((prev) => [...prev, null]);
  }

  function removeItem(index: number) {
    remove(index);
    setSelectedProducts((prev) => prev.filter((_, i) => i !== index));
  }

  function handleSubmit(values: PurchaseFormValues) {
    onSubmit({
      supplier_id: values.supplier_id,
      purchased_at: values.purchased_at,
      invoice_number: values.invoice_number || null,
      items: values.items.map((item) => ({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
      })),
    });
  }

  const itemsError = form.formState.errors.items;
  const itemsRootMessage = itemsError && !Array.isArray(itemsError) ? itemsError.message : undefined;

  return (
    <form id={formId} onSubmit={form.handleSubmit(handleSubmit)} noValidate className="flex flex-col gap-6">
      {errorMessage ? (
        <Alert variant="destructive">
          <AlertDescription>
            {errorMessage}
            {errorDetails && errorDetails.length > 0 ? (
              <ul className="mt-1 list-disc pl-4">
                {errorDetails.map((detail) => (
                  <li key={detail}>{detail}</li>
                ))}
              </ul>
            ) : null}
          </AlertDescription>
        </Alert>
      ) : null}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field data-invalid={!!form.formState.errors.supplier_id} className="sm:col-span-2">
          <FieldLabel htmlFor="supplier_id">Fornecedor</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="supplier_id"
              render={({ field }) => (
                <SupplierCombobox
                  id="supplier_id"
                  value={selectedSupplier}
                  invalid={!!form.formState.errors.supplier_id}
                  onChange={(supplier) => {
                    setSelectedSupplier(supplier);
                    field.onChange(supplier?.id);
                  }}
                />
              )}
            />
            <FieldError errors={[form.formState.errors.supplier_id]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.purchased_at}>
          <FieldLabel htmlFor="purchased_at">Data da compra</FieldLabel>
          <FieldContent>
            <Input
              id="purchased_at"
              type="date"
              className="h-11 md:h-9"
              aria-invalid={!!form.formState.errors.purchased_at}
              {...form.register("purchased_at")}
            />
            <FieldError errors={[form.formState.errors.purchased_at]} />
          </FieldContent>
        </Field>

        <Field>
          <FieldLabel htmlFor="invoice_number">Número da NF (opcional)</FieldLabel>
          <FieldContent>
            <Input id="invoice_number" className="h-11 md:h-9" {...form.register("invoice_number")} />
          </FieldContent>
        </Field>
      </div>

      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-base font-semibold text-foreground">Itens</h2>
          <Button type="button" variant="outline" size="sm" className="h-9" onClick={addItem}>
            <Plus className="size-4" />
            Adicionar item
          </Button>
        </div>

        {itemsRootMessage ? <p className="text-sm text-destructive">{itemsRootMessage}</p> : null}

        <div className="flex flex-col gap-3">
          {fields.map((field, index) => {
            const itemErrors = Array.isArray(itemsError) ? itemsError[index] : undefined;
            const item = watchedItems[index];
            const itemTotal = (Number(item?.quantity) || 0) * (Number(item?.unit_price) || 0);

            return (
              <div key={field.id} className="rounded-lg border border-border p-3">
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-[1fr_110px_130px_130px_auto] sm:items-end">
                  <Field data-invalid={!!itemErrors?.product_id}>
                    <FieldLabel htmlFor={`items.${index}.product_id`}>Produto</FieldLabel>
                    <FieldContent>
                      <Controller
                        control={form.control}
                        name={`items.${index}.product_id`}
                        render={({ field: productField }) => (
                          <ProductCombobox
                            id={`items.${index}.product_id`}
                            value={selectedProducts[index] ?? null}
                            invalid={!!itemErrors?.product_id}
                            onChange={(product) => {
                              setSelectedProducts((prev) => {
                                const next = [...prev];
                                next[index] = product;
                                return next;
                              });
                              productField.onChange(product?.id);
                            }}
                          />
                        )}
                      />
                      <FieldError errors={[itemErrors?.product_id]} />
                    </FieldContent>
                  </Field>

                  <Field data-invalid={!!itemErrors?.quantity}>
                    <FieldLabel htmlFor={`items.${index}.quantity`}>Quantidade</FieldLabel>
                    <FieldContent>
                      <Input
                        id={`items.${index}.quantity`}
                        type="number"
                        step="0.0001"
                        min="0.0001"
                        className="h-11 md:h-9"
                        aria-invalid={!!itemErrors?.quantity}
                        {...form.register(`items.${index}.quantity`)}
                      />
                      <FieldError errors={[itemErrors?.quantity]} />
                    </FieldContent>
                  </Field>

                  <Field data-invalid={!!itemErrors?.unit_price}>
                    <FieldLabel htmlFor={`items.${index}.unit_price`}>Preço unitário</FieldLabel>
                    <FieldContent>
                      <Input
                        id={`items.${index}.unit_price`}
                        type="number"
                        step="0.01"
                        min="0"
                        className="h-11 md:h-9"
                        aria-invalid={!!itemErrors?.unit_price}
                        {...form.register(`items.${index}.unit_price`)}
                      />
                      <FieldError errors={[itemErrors?.unit_price]} />
                    </FieldContent>
                  </Field>

                  <Field>
                    <FieldLabel className="sm:hidden">Total do item</FieldLabel>
                    <FieldContent>
                      <div className="flex h-11 items-center text-sm font-medium text-foreground md:h-9">
                        {formatCurrency(String(itemTotal))}
                      </div>
                    </FieldContent>
                  </Field>

                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="h-11 w-11 shrink-0 self-end text-muted-foreground hover:text-destructive md:h-9 md:w-9"
                    onClick={() => removeItem(index)}
                    disabled={fields.length === 1}
                    aria-label="Remover item"
                  >
                    <Trash2 className="size-4" />
                  </Button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="flex items-center justify-end gap-2 border-t border-border pt-4">
        <span className="text-sm text-muted-foreground">Total da compra</span>
        <span className="text-lg font-semibold text-foreground">{formatCurrency(String(total))}</span>
      </div>
    </form>
  );
}
