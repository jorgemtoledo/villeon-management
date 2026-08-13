"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Field,
  FieldContent,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";

const loginSchema = z.object({
  email: z.string().min(1, "Informe seu e-mail.").email("E-mail inválido."),
  password: z.string().min(1, "Informe sua senha."),
});

type LoginValues = z.infer<typeof loginSchema>;

export function LoginForm() {
  const router = useRouter();
  const { login, isSubmitting, error, status } = useAuth();

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  useEffect(() => {
    if (status === "authenticated") {
      router.replace("/produtos");
    }
  }, [status, router]);

  async function onSubmit(values: LoginValues) {
    try {
      await login(values.email, values.password);
    } catch {
      // error is already surfaced via useAuth().error
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} noValidate>
      <FieldGroup>
        {error ? (
          <Alert variant="destructive">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        <Field data-invalid={!!form.formState.errors.email}>
          <FieldLabel htmlFor="email">E-mail</FieldLabel>
          <FieldContent>
            <Input
              id="email"
              type="email"
              autoComplete="username"
              placeholder="voce@villeon.com.br"
              aria-invalid={!!form.formState.errors.email}
              {...form.register("email")}
            />
            <FieldError errors={[form.formState.errors.email]} />
          </FieldContent>
        </Field>

        <Field data-invalid={!!form.formState.errors.password}>
          <FieldLabel htmlFor="password">Senha</FieldLabel>
          <FieldContent>
            <Input
              id="password"
              type="password"
              autoComplete="current-password"
              aria-invalid={!!form.formState.errors.password}
              {...form.register("password")}
            />
            <FieldError errors={[form.formState.errors.password]} />
          </FieldContent>
        </Field>

        <Button type="submit" disabled={isSubmitting} className="w-full">
          {isSubmitting ? "Entrando..." : "Entrar"}
        </Button>
      </FieldGroup>
    </form>
  );
}
