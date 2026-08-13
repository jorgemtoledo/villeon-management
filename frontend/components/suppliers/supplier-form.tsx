"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

import { formatCnpj } from "@/lib/format-cnpj";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Input } from "@/components/ui/input";
import {
  Field,
  FieldContent,
  FieldError,
  FieldLabel,
} from "@/components/ui/field";
import type { Supplier, SupplierInput } from "@/types/supplier";

// Mirrors Api::V1::SuppliersController#supplier_params exactly — only name
// and cnpj exist on Supplier (see schema.rb), active never appears here.
//
// CNPJ validation is deliberately light here: just "does it have 14 digits
// once the mask is stripped, if the user typed anything at all". The real
// authority — format + mod-11 check digit + uniqueness — is the backend
// (Cnpj/CnpjValidator, already covered by its own specs); duplicating that
// checksum algorithm in TypeScript would just be a second place for it to
// drift out of sync. A 422 from the API surfaces here as a friendly message
// either way (see errorDetails below).
const supplierSchema = z.object({
  name: z.string().min(1, "Informe o nome."),
  cnpj: z
    .string()
    .optional()
    .refine((value) => !value || value.replace(/\D/g, "").length === 14, {
      message: "CNPJ deve ter 14 dígitos.",
    }),
});

type SupplierFormValues = z.infer<typeof supplierSchema>;

interface SupplierFormProps {
  formId: string;
  supplier?: Supplier;
  onSubmit: (input: SupplierInput) => void;
  errorMessage?: string | null;
  errorDetails?: string[];
}

export function SupplierForm({ formId, supplier, onSubmit, errorMessage, errorDetails }: SupplierFormProps) {
  const form = useForm<SupplierFormValues>({
    resolver: zodResolver(supplierSchema),
    defaultValues: {
      name: supplier?.name ?? "",
      cnpj: supplier?.cnpj ? formatCnpj(supplier.cnpj) : "",
    },
  });

  function handleSubmit(values: SupplierFormValues) {
    onSubmit({
      name: values.name,
      cnpj: values.cnpj?.trim() ? values.cnpj : null,
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

      <Field data-invalid={!!form.formState.errors.name}>
        <FieldLabel htmlFor="name">Nome</FieldLabel>
        <FieldContent>
          <Input id="name" aria-invalid={!!form.formState.errors.name} {...form.register("name")} />
          <FieldError errors={[form.formState.errors.name]} />
        </FieldContent>
      </Field>

      <Field data-invalid={!!form.formState.errors.cnpj}>
        <FieldLabel htmlFor="cnpj">CNPJ (opcional)</FieldLabel>
        <FieldContent>
          <Input
            id="cnpj"
            placeholder="00.000.000/0000-00"
            aria-invalid={!!form.formState.errors.cnpj}
            {...form.register("cnpj")}
          />
          <FieldError errors={[form.formState.errors.cnpj]} />
        </FieldContent>
      </Field>
    </form>
  );
}
