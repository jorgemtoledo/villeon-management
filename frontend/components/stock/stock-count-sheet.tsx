"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";

import { useProductStock } from "@/hooks/use-product-stock";
import { useCreateStockCount } from "@/hooks/use-stock-count-mutations";
import { ApiError } from "@/lib/api/client";
import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Field, FieldContent, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { StockPriorityStep } from "@/components/stock/stock-priority-step";
import type { ProductStock } from "@/types/product-stock";

// Only non-negative — mirrors StockCount#quantity's own validation. The
// backend remains the real authority; this is immediate feedback only.
const countSchema = z.object({
  quantity: z.coerce.number({ error: "Informe a quantidade contada." }).min(0, "Não pode ser negativo."),
});

type CountInput = z.input<typeof countSchema>;
type CountValues = z.output<typeof countSchema>;

const FORM_ID = "stock-count-form";

interface StockCountSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  // undefined while closed — the row being counted, once a "Contar"/
  // "Atualizar" action is clicked.
  row: ProductStock | undefined;
  // Bloco 6G Parte 4.1: lets the "Configuração de compra" column open the
  // priority step directly, without going through a new count — the row is
  // already status "comprar" (that column is only clickable then), so
  // there's nothing to count first.
  openToPriority?: boolean;
}

export function StockCountSheet({ open, onOpenChange, row, openToPriority = false }: StockCountSheetProps) {
  // Hooks can't be called conditionally — a placeholder id while closed is
  // harmless, the mutation only ever fires from an actual submit with `row` set.
  const mutation = useCreateStockCount(row?.product.id ?? -1);

  // Bloco 6G Parte 4: after the count is saved, the *new* status (not
  // `row.status`, which reflects the previous count) decides whether to show
  // a second step for priority/needs_advance_order — never recomputed
  // client-side, always re-fetched from the backend, the only source of
  // truth for status. `showPriorityStep` gates which step renders.
  const [ showPriorityStep, setShowPriorityStep ] = useState(openToPriority);
  const stockQuery = useProductStock(row?.product.id);

  // Resets `showPriorityStep` to the caller's intent whenever a different
  // product is targeted — adjusting state during render (not in an effect)
  // per React's guidance for state that must reset on a prop/identity
  // change: https://react.dev/learn/you-might-not-need-an-effect. Tracking
  // just the product id is enough because the page always changes `row` and
  // `openToPriority` together (never one without the other) whenever it
  // opens the sheet.
  const [ lastRowId, setLastRowId ] = useState(row?.product.id);
  if (row?.product.id !== lastRowId) {
    setLastRowId(row?.product.id);
    setShowPriorityStep(openToPriority);
  }

  const form = useForm<CountInput, unknown, CountValues>({
    resolver: zodResolver(countSchema),
    values: row ? { quantity: row.current_quantity !== null ? Number(row.current_quantity) : 0 } : undefined,
  });

  function handleSubmit(values: CountValues) {
    if (!row) return;

    mutation.mutate(
      { quantity: values.quantity },
      {
        onSuccess: async () => {
          const result = await stockQuery.refetch();

          if (result.data?.status === "comprar") {
            setShowPriorityStep(true);
          } else {
            toast.success(`Contagem de "${row.product.name}" salva.`);
            onOpenChange(false);
          }
        },
      },
    );
  }

  function handleClose(next: boolean) {
    if (!next) {
      mutation.reset();
      setShowPriorityStep(false);
    }
    onOpenChange(next);
  }

  const error = mutation.error;
  const errorMessage =
    error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar a contagem." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  // Falls back to the list row while the fresh GET is in flight (opening
  // straight to this step via openToPriority has nothing else to show yet)
  // — replaced by stockQuery.data, the real source of truth, as soon as it
  // resolves.
  const priorityStock = showPriorityStep ? (stockQuery.data ?? row) : undefined;

  return (
    <Sheet open={open} onOpenChange={handleClose}>
      <SheetContent side="right" className="w-full sm:max-w-md">
        <SheetHeader>
          <SheetTitle>
            {row ? (priorityStock ? `Prioridade — ${row.product.name}` : `Contagem — ${row.product.name}`) : "Contagem"}
          </SheetTitle>
          <SheetDescription>
            {row && !priorityStock
              ? `Informe a quantidade contada em ${row.stock_unit?.abbreviation ?? "unidade"}. Status atual: ${STOCK_STATUS_LABEL[row.status]}.`
              : ""}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto px-4 py-1">
          {priorityStock ? (
            <StockPriorityStep stock={priorityStock} onDone={() => handleClose(false)} />
          ) : (
            <>
              {errorMessage ? (
                <Alert variant="destructive" className="mb-4">
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

              {row ? (
                <form
                  id={FORM_ID}
                  onSubmit={form.handleSubmit(handleSubmit)}
                  noValidate
                  className="flex flex-col gap-4"
                >
                  <Field data-invalid={!!form.formState.errors.quantity}>
                    <FieldLabel htmlFor="quantity">Quantidade contada</FieldLabel>
                    <FieldContent>
                      <Input
                        id="quantity"
                        type="number"
                        step="0.0001"
                        min="0"
                        autoFocus
                        aria-invalid={!!form.formState.errors.quantity}
                        {...form.register("quantity")}
                      />
                      <FieldError errors={[ form.formState.errors.quantity ]} />
                    </FieldContent>
                  </Field>

                  {row.current_quantity !== null ? (
                    <p className="text-sm text-muted-foreground">
                      Última contagem: {formatStockQuantity(row.current_quantity)} {row.stock_unit?.abbreviation ?? ""}
                    </p>
                  ) : null}
                </form>
              ) : null}
            </>
          )}
        </div>

        {priorityStock ? null : (
          <SheetFooter className="flex-row justify-end gap-2">
            <Button type="button" variant="outline" className="h-11 md:h-9" onClick={() => handleClose(false)}>
              Cancelar
            </Button>
            <Button type="submit" form={FORM_ID} disabled={mutation.isPending || !row} className="h-11 md:h-9">
              {mutation.isPending ? "Salvando..." : "Salvar contagem"}
            </Button>
          </SheetFooter>
        )}
      </SheetContent>
    </Sheet>
  );
}
