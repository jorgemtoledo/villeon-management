"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";

import { useProductStock } from "@/hooks/use-product-stock";
import { useUpdateProductStockConfig } from "@/hooks/use-product-stock-mutations";
import { ApiError } from "@/lib/api/client";
import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_STATUS_BADGE_VARIANT, STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Field, FieldContent, FieldError, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import type { Product } from "@/types/product";

// Mirrors ProductStock model validations: both non-negative, ideal >= minimum.
// The backend is the real authority (Bloco 6G Parte 2) — this only gives
// immediate feedback instead of a round-trip for the common mistakes.
const stockConfigSchema = z
  .object({
    minimum_quantity: z.coerce.number({ error: "Informe o estoque mínimo." }).min(0, "Não pode ser negativo."),
    ideal_quantity: z.coerce.number({ error: "Informe o estoque ideal." }).min(0, "Não pode ser negativo."),
  })
  .refine((data) => data.ideal_quantity >= data.minimum_quantity, {
    message: "O estoque ideal não pode ser menor que o mínimo.",
    path: [ "ideal_quantity" ],
  });

type StockConfigInput = z.input<typeof stockConfigSchema>;
type StockConfigValues = z.output<typeof stockConfigSchema>;

const FORM_ID = "product-stock-config-form";

// Only rendered in edit mode (a product must already exist to have a stock
// resource) — admin-only, same as the sheet that hosts it. The backend
// enforces this independently (Ability denies manager/operator on
// ProductStock#update regardless of what the frontend hides).
export function ProductStockConfigForm({ product }: { product: Product }) {
  const { data: stock, isPending, isError, refetch } = useProductStock(product.id);
  const mutation = useUpdateProductStockConfig(product.id);

  const form = useForm<StockConfigInput, unknown, StockConfigValues>({
    resolver: zodResolver(stockConfigSchema),
    values: stock
      ? {
          minimum_quantity: Number(stock.minimum_quantity ?? 0),
          ideal_quantity: Number(stock.ideal_quantity ?? 0),
        }
      : undefined,
  });

  function handleSubmit(values: StockConfigValues) {
    mutation.mutate(values, {
      onSuccess: () => toast.success("Configuração de estoque salva."),
    });
  }

  const error = mutation.error;
  const errorMessage =
    error instanceof ApiError
      ? error.message
      : error
        ? "Erro inesperado ao salvar a configuração de estoque."
        : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <Card size="sm" className="mt-4">
      <CardHeader>
        <CardTitle>Reposição de estoque</CardTitle>
        <CardDescription>
          Esses valores controlam a reposição: quando o estoque contado ficar igual ou abaixo do mínimo, o sistema
          sinaliza que é preciso comprar até atingir o ideal.
        </CardDescription>
      </CardHeader>

      <CardContent className="flex flex-col gap-4">
        {isPending ? (
          <div className="flex flex-col gap-2">
            <Skeleton className="h-9 w-full" />
            <Skeleton className="h-9 w-full" />
          </div>
        ) : isError ? (
          <Alert variant="destructive">
            <AlertDescription>
              Não foi possível carregar a configuração de estoque.{" "}
              <button type="button" className="underline" onClick={() => refetch()}>
                Tentar novamente
              </button>
            </AlertDescription>
          </Alert>
        ) : stock ? (
          <>
            <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
              <span>Status atual:</span>
              <Badge variant={STOCK_STATUS_BADGE_VARIANT[stock.status]}>{STOCK_STATUS_LABEL[stock.status]}</Badge>
              {stock.current_quantity !== null ? (
                <span>
                  Estoque contado: {formatStockQuantity(stock.current_quantity)} {stock.stock_unit?.abbreviation ?? ""}
                </span>
              ) : null}
            </div>

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

            <form
              id={FORM_ID}
              onSubmit={form.handleSubmit(handleSubmit)}
              noValidate
              className="grid grid-cols-1 gap-4 sm:grid-cols-2"
            >
              <Field data-invalid={!!form.formState.errors.minimum_quantity}>
                <FieldLabel htmlFor="minimum_quantity">Estoque mínimo</FieldLabel>
                <FieldContent>
                  <Input
                    id="minimum_quantity"
                    type="number"
                    step="0.0001"
                    min="0"
                    aria-invalid={!!form.formState.errors.minimum_quantity}
                    {...form.register("minimum_quantity")}
                  />
                  <FieldError errors={[ form.formState.errors.minimum_quantity ]} />
                </FieldContent>
              </Field>

              <Field data-invalid={!!form.formState.errors.ideal_quantity}>
                <FieldLabel htmlFor="ideal_quantity">Estoque ideal</FieldLabel>
                <FieldContent>
                  <Input
                    id="ideal_quantity"
                    type="number"
                    step="0.0001"
                    min="0"
                    aria-invalid={!!form.formState.errors.ideal_quantity}
                    {...form.register("ideal_quantity")}
                  />
                  <FieldError errors={[ form.formState.errors.ideal_quantity ]} />
                </FieldContent>
              </Field>
            </form>

            <Button
              type="submit"
              form={FORM_ID}
              variant="outline"
              className="h-11 self-end md:h-9"
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Salvando..." : "Salvar configuração de estoque"}
            </Button>
          </>
        ) : null}
      </CardContent>
    </Card>
  );
}
