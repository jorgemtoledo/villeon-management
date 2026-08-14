"use client";

import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

import { useUnits } from "@/hooks/use-units";
import { useSubcategories } from "@/hooks/use-subcategories";
import { SECTORS } from "@/lib/constants/sectors";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Input } from "@/components/ui/input";
import {
  Field,
  FieldContent,
  FieldError,
  FieldLabel,
} from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { Product, ProductInput } from "@/types/product";

// Mirrors Api::V1::ProductsController#product_params exactly — same fields,
// same required/optional split as the backend (see Product model
// validations). category_id is intentionally absent: 0 Category rows exist
// today (that taxonomy isn't confirmed with the client). subcategory_id
// IS present — it's the client's own flat "Subcategoria" code list (Bloco
// Subcategoria), a real, already-imported reference table, unlike Category.
const productSchema = z.object({
  name: z.string().min(1, "Informe o nome."),
  code: z.string().min(1, "Informe o código."),
  sector_id: z.coerce.number({ error: "Selecione o setor." }).int().positive("Selecione o setor."),
  // Optional — "" (nothing selected/cleared) preprocesses to undefined
  // rather than coercing to NaN/0, same reasoning as PurchaseForm's
  // requiredCoercedNumber, just optional instead of required here.
  subcategory_id: z.preprocess(
    (val) => (val === "" ? undefined : val),
    z.coerce.number().int().positive().optional(),
  ),
  purchase_unit_id: z.coerce
    .number({ error: "Selecione a unidade de compra." })
    .int()
    .positive("Selecione a unidade de compra."),
  stock_unit_id: z.coerce
    .number({ error: "Selecione a unidade de estoque." })
    .int()
    .positive("Selecione a unidade de estoque."),
  conversion_factor: z.coerce
    .number({ error: "Informe o fator de conversão." })
    .positive("O fator de conversão deve ser maior que zero."),
  colibri_code: z.string().optional(),
});

type ProductFormInput = z.input<typeof productSchema>;
type ProductFormValues = z.output<typeof productSchema>;

interface ProductFormProps {
  formId: string;
  product?: Product;
  onSubmit: (input: ProductInput) => void;
  errorMessage?: string | null;
  errorDetails?: string[];
  // manager/operator open the same sheet as admin but can't submit it — a
  // fieldset disables every native input in one shot; the three Selects
  // (Base UI, not native <select>s) need `disabled` passed explicitly since
  // they don't inherit it from the surrounding fieldset.
  readOnly?: boolean;
}

export function ProductForm({
  formId,
  product,
  onSubmit,
  errorMessage,
  errorDetails,
  readOnly = false,
}: ProductFormProps) {
  const { data: unitsData, isPending: unitsPending } = useUnits();
  const units = unitsData?.data ?? [];
  const { data: subcategoriesData, isPending: subcategoriesPending } = useSubcategories();
  const subcategories = subcategoriesData?.data ?? [];

  const form = useForm<ProductFormInput, unknown, ProductFormValues>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      name: product?.name ?? "",
      code: product?.code ?? "",
      sector_id: product?.sector?.id,
      subcategory_id: product?.subcategory?.id,
      purchase_unit_id: product?.purchase_unit?.id,
      stock_unit_id: product?.stock_unit?.id,
      conversion_factor: product?.conversion_factor ?? 1,
      colibri_code: product?.colibri_code ?? "",
    },
  });

  function handleSubmit(values: ProductFormValues) {
    onSubmit({
      name: values.name,
      code: values.code,
      sector_id: values.sector_id,
      subcategory_id: values.subcategory_id ?? null,
      purchase_unit_id: values.purchase_unit_id,
      stock_unit_id: values.stock_unit_id,
      conversion_factor: values.conversion_factor,
      colibri_code: values.colibri_code || null,
    });
  }

  return (
    <form id={formId} onSubmit={form.handleSubmit(handleSubmit)} noValidate className="flex flex-col gap-4">
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

      <fieldset disabled={readOnly} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field data-invalid={!!form.formState.errors.code}>
          <FieldLabel htmlFor="code">Código</FieldLabel>
          <FieldContent>
            <Input id="code" aria-invalid={!!form.formState.errors.code} {...form.register("code")} />
            <FieldError errors={[form.formState.errors.code]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.name}>
          <FieldLabel htmlFor="name">Nome</FieldLabel>
          <FieldContent>
            <Input id="name" aria-invalid={!!form.formState.errors.name} {...form.register("name")} />
            <FieldError errors={[form.formState.errors.name]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.sector_id}>
          <FieldLabel htmlFor="sector_id">Setor</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="sector_id"
              render={({ field }) => (
                <Select
                  value={field.value !== undefined ? String(field.value) : ""}
                  onValueChange={(value) => field.onChange(Number(value))}
                  disabled={readOnly}
                  items={Object.fromEntries(SECTORS.map((sector) => [String(sector.id), sector.name]))}
                >
                  <SelectTrigger
                    id="sector_id"
                    className="h-11 w-full md:h-9"
                    aria-invalid={!!form.formState.errors.sector_id}
                  >
                    <SelectValue placeholder="Selecione o setor" />
                  </SelectTrigger>
                  <SelectContent>
                    {SECTORS.map((sector) => (
                      <SelectItem key={sector.id} value={String(sector.id)}>
                        {sector.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError errors={[form.formState.errors.sector_id]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.subcategory_id}>
          <FieldLabel htmlFor="subcategory_id">Subcategoria</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="subcategory_id"
              render={({ field }) => (
                <Select
                  value={field.value !== undefined ? String(field.value) : ""}
                  onValueChange={(value) => field.onChange(value === "" ? undefined : Number(value))}
                  disabled={readOnly || subcategoriesPending}
                  items={{
                    "": "Sem subcategoria",
                    ...Object.fromEntries(
                      subcategories.map((subcategory) => [String(subcategory.id), subcategory.code]),
                    ),
                  }}
                >
                  <SelectTrigger
                    id="subcategory_id"
                    className="h-11 w-full md:h-9"
                    aria-invalid={!!form.formState.errors.subcategory_id}
                  >
                    <SelectValue placeholder={subcategoriesPending ? "Carregando..." : "Sem subcategoria"} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Sem subcategoria</SelectItem>
                    {subcategories.map((subcategory) => (
                      <SelectItem key={subcategory.id} value={String(subcategory.id)}>
                        {subcategory.code}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError errors={[form.formState.errors.subcategory_id]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.conversion_factor}>
          <FieldLabel htmlFor="conversion_factor">Fator de conversão</FieldLabel>
          <FieldContent>
            <Input
              id="conversion_factor"
              type="number"
              step="0.0001"
              min="0.0001"
              aria-invalid={!!form.formState.errors.conversion_factor}
              {...form.register("conversion_factor")}
            />
            <FieldError errors={[form.formState.errors.conversion_factor]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.purchase_unit_id}>
          <FieldLabel htmlFor="purchase_unit_id">Unidade de compra</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="purchase_unit_id"
              render={({ field }) => (
                <Select
                  value={field.value !== undefined ? String(field.value) : ""}
                  onValueChange={(value) => field.onChange(Number(value))}
                  disabled={readOnly || unitsPending}
                  items={Object.fromEntries(
                    units.map((unit) => [String(unit.id), `${unit.name} (${unit.abbreviation})`]),
                  )}
                >
                  <SelectTrigger
                    id="purchase_unit_id"
                    className="h-11 w-full md:h-9"
                    aria-invalid={!!form.formState.errors.purchase_unit_id}
                  >
                    <SelectValue placeholder={unitsPending ? "Carregando..." : "Selecione a unidade"} />
                  </SelectTrigger>
                  <SelectContent>
                    {units.map((unit) => (
                      <SelectItem key={unit.id} value={String(unit.id)}>
                        {unit.name} ({unit.abbreviation})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError errors={[form.formState.errors.purchase_unit_id]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.stock_unit_id}>
          <FieldLabel htmlFor="stock_unit_id">Unidade de estoque</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="stock_unit_id"
              render={({ field }) => (
                <Select
                  value={field.value !== undefined ? String(field.value) : ""}
                  onValueChange={(value) => field.onChange(Number(value))}
                  disabled={readOnly || unitsPending}
                  items={Object.fromEntries(
                    units.map((unit) => [String(unit.id), `${unit.name} (${unit.abbreviation})`]),
                  )}
                >
                  <SelectTrigger
                    id="stock_unit_id"
                    className="h-11 w-full md:h-9"
                    aria-invalid={!!form.formState.errors.stock_unit_id}
                  >
                    <SelectValue placeholder={unitsPending ? "Carregando..." : "Selecione a unidade"} />
                  </SelectTrigger>
                  <SelectContent>
                    {units.map((unit) => (
                      <SelectItem key={unit.id} value={String(unit.id)}>
                        {unit.name} ({unit.abbreviation})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError errors={[form.formState.errors.stock_unit_id]} />
          </FieldContent>
        </Field>
      </div>

      <Field>
        <FieldLabel htmlFor="colibri_code">Código Colibri (opcional)</FieldLabel>
        <FieldContent>
          <Input id="colibri_code" {...form.register("colibri_code")} />
        </FieldContent>
      </Field>
      </fieldset>
    </form>
  );
}
