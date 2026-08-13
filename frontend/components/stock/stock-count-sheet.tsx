"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";

import { useCreateStockCount } from "@/hooks/use-stock-count-mutations";
import { ApiError } from "@/lib/api/client";
import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Field, FieldContent, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle } from "@/components/ui/sheet";
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
}

export function StockCountSheet({ open, onOpenChange, row }: StockCountSheetProps) {
  // Hooks can't be called conditionally — a placeholder id while closed is
  // harmless, the mutation only ever fires from an actual submit with `row` set.
  const mutation = useCreateStockCount(row?.product.id ?? -1);

  const form = useForm<CountInput, unknown, CountValues>({
    resolver: zodResolver(countSchema),
    values: row ? { quantity: row.current_quantity !== null ? Number(row.current_quantity) : 0 } : undefined,
  });

  function handleSubmit(values: CountValues) {
    if (!row) return;

    mutation.mutate(
      { quantity: values.quantity },
      {
        onSuccess: () => {
          toast.success(`Contagem de "${row.product.name}" salva.`);
          onOpenChange(false);
        },
      },
    );
  }

  const error = mutation.error;
  const errorMessage =
    error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar a contagem." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <Sheet
      open={open}
      onOpenChange={(next) => {
        if (!next) mutation.reset();
        onOpenChange(next);
      }}
    >
      <SheetContent side="right" className="w-full sm:max-w-md">
        <SheetHeader>
          <SheetTitle>{row ? `Contagem — ${row.product.name}` : "Contagem"}</SheetTitle>
          <SheetDescription>
            {row
              ? `Informe a quantidade contada em ${row.stock_unit?.abbreviation ?? "unidade"}. Status atual: ${STOCK_STATUS_LABEL[row.status]}.`
              : ""}
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 overflow-y-auto px-4 py-1">
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
        </div>

        <SheetFooter className="flex-row justify-end gap-2">
          <Button type="button" variant="outline" className="h-11 md:h-9" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button type="submit" form={FORM_ID} disabled={mutation.isPending || !row} className="h-11 md:h-9">
            {mutation.isPending ? "Salvando..." : "Salvar contagem"}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
