"use client";

import { Controller, useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

import { SECTORS } from "@/lib/constants/sectors";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
import type { User, UserInput } from "@/types/user";

const ROLE_LABELS = {
  admin: "Administrador",
  manager: "Gerente",
  operator: "Operador",
};

// Password rules mirror Devise's :validatable defaults (min length 6,
// confirmation match) — required only when creating (isEditing=false).
// Blank on edit means "don't change it", matching the backend's contract.
function buildUserSchema(isEditing: boolean) {
  return z
    .object({
      name: z.string().min(1, "Informe o nome."),
      email: z.string().min(1, "Informe o e-mail.").email("Informe um e-mail válido."),
      role: z.enum(["admin", "manager", "operator"], { error: "Selecione o papel." }),
      all_sectors: z.boolean(),
      sector_ids: z.array(z.number()),
      password: z.string().optional(),
      password_confirmation: z.string().optional(),
    })
    .superRefine((values, ctx) => {
      const password = values.password ?? "";
      const confirmation = values.password_confirmation ?? "";

      if (!isEditing && password.length === 0) {
        ctx.addIssue({ code: "custom", path: [ "password" ], message: "Informe uma senha." });
      }
      if (password.length > 0 && password.length < 6) {
        ctx.addIssue({ code: "custom", path: [ "password" ], message: "A senha deve ter ao menos 6 caracteres." });
      }
      if (password !== confirmation) {
        ctx.addIssue({ code: "custom", path: [ "password_confirmation" ], message: "As senhas não coincidem." });
      }
    });
}

type UserFormValues = z.infer<ReturnType<typeof buildUserSchema>>;

interface UserFormProps {
  formId: string;
  user?: User;
  onSubmit: (input: UserInput) => void;
  errorMessage?: string | null;
  errorDetails?: string[];
}

export function UserForm({ formId, user, onSubmit, errorMessage, errorDetails }: UserFormProps) {
  const isEditing = !!user;

  const form = useForm<UserFormValues>({
    resolver: zodResolver(buildUserSchema(isEditing)),
    defaultValues: {
      name: user?.name ?? "",
      email: user?.email ?? "",
      role: user?.role ?? "operator",
      all_sectors: user?.all_sectors ?? false,
      sector_ids: user?.sector_ids ?? [],
      password: "",
      password_confirmation: "",
    },
  });

  const allSectors = useWatch({ control: form.control, name: "all_sectors" });

  function handleSubmit(values: UserFormValues) {
    const input: UserInput = {
      name: values.name,
      email: values.email,
      role: values.role,
      all_sectors: values.all_sectors,
      sector_ids: values.all_sectors ? [] : values.sector_ids,
    };
    // Omit password entirely when blank on an edit — apply_user_params on
    // the backend leaves the existing password untouched only when the key
    // is genuinely absent (Devise checks !password.nil?, not blank).
    if (values.password) {
      input.password = values.password;
      input.password_confirmation = values.password_confirmation;
    }

    onSubmit(input);
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

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field data-invalid={!!form.formState.errors.name}>
          <FieldLabel htmlFor="name">Nome</FieldLabel>
          <FieldContent>
            <Input id="name" aria-invalid={!!form.formState.errors.name} {...form.register("name")} />
            <FieldError errors={[ form.formState.errors.name ]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.email}>
          <FieldLabel htmlFor="email">E-mail</FieldLabel>
          <FieldContent>
            <Input id="email" type="email" aria-invalid={!!form.formState.errors.email} {...form.register("email")} />
            <FieldError errors={[ form.formState.errors.email ]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.role}>
          <FieldLabel htmlFor="role">Papel</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="role"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange} items={ROLE_LABELS}>
                  <SelectTrigger id="role" className="h-11 w-full md:h-9" aria-invalid={!!form.formState.errors.role}>
                    <SelectValue placeholder="Selecione o papel" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Administrador</SelectItem>
                    <SelectItem value="manager">Gerente</SelectItem>
                    <SelectItem value="operator">Operador</SelectItem>
                  </SelectContent>
                </Select>
              )}
            />
            <FieldError errors={[ form.formState.errors.role ]} />
          </FieldContent>
        </Field>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field data-invalid={!!form.formState.errors.password}>
          <FieldLabel htmlFor="password">{isEditing ? "Nova senha (opcional)" : "Senha"}</FieldLabel>
          <FieldContent>
            <Input
              id="password"
              type="password"
              autoComplete="new-password"
              aria-invalid={!!form.formState.errors.password}
              {...form.register("password")}
            />
            <FieldError errors={[ form.formState.errors.password ]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.password_confirmation}>
          <FieldLabel htmlFor="password_confirmation">Confirmar senha</FieldLabel>
          <FieldContent>
            <Input
              id="password_confirmation"
              type="password"
              autoComplete="new-password"
              aria-invalid={!!form.formState.errors.password_confirmation}
              {...form.register("password_confirmation")}
            />
            <FieldError errors={[ form.formState.errors.password_confirmation ]} />
          </FieldContent>
        </Field>
      </div>

      <Field>
        <FieldContent>
          <Controller
            control={form.control}
            name="all_sectors"
            render={({ field }) => (
              <Label htmlFor="all_sectors" className="flex w-fit items-center gap-2 font-normal">
                <Checkbox
                  id="all_sectors"
                  checked={field.value}
                  onCheckedChange={(checked) => {
                    field.onChange(checked);
                    // Selecting "todos os setores" makes the individual
                    // picks meaningless — clearing them keeps the payload
                    // matching the all_sectors=true/sector_ids=[] contract
                    // (Felipe/Fran) instead of sending stale ids.
                    if (checked) form.setValue("sector_ids", []);
                  }}
                />
                Todos os setores
              </Label>
            )}
          />
        </FieldContent>
      </Field>

      {!allSectors ? (
        <Field>
          <FieldLabel>Setores específicos</FieldLabel>
          <FieldContent>
            <Controller
              control={form.control}
              name="sector_ids"
              render={({ field }) => (
                <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:gap-4">
                  {SECTORS.map((sector) => (
                    <Label
                      key={sector.id}
                      htmlFor={`sector-${sector.id}`}
                      className="flex w-fit items-center gap-2 font-normal"
                    >
                      <Checkbox
                        id={`sector-${sector.id}`}
                        checked={field.value.includes(sector.id)}
                        onCheckedChange={(checked) => {
                          field.onChange(
                            checked
                              ? [ ...field.value, sector.id ]
                              : field.value.filter((id: number) => id !== sector.id),
                          );
                        }}
                      />
                      {sector.name}
                    </Label>
                  ))}
                </div>
              )}
            />
          </FieldContent>
        </Field>
      ) : null}
    </form>
  );
}
