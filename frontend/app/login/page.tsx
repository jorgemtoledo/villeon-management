import type { Metadata } from "next";
import Image from "next/image";

import { LoginForm } from "@/components/auth/login-form";

export const metadata: Metadata = {
  title: "Entrar — VILLEON Gestão",
};

export default function LoginPage() {
  return (
    <div className="grid min-h-svh grid-cols-1 lg:grid-cols-2">
      <div className="flex flex-col items-center justify-center gap-6 bg-villeon-green-900 p-8 lg:p-12">
        <Image
          src="/brand/villeon-logo-full.png"
          alt="VILLEON Restaurant"
          width={757}
          height={431}
          sizes="(min-width: 640px) 256px, 224px"
          className="h-auto w-56 rounded-lg sm:w-64"
          priority
        />
        <p className="max-w-xs text-center text-sm text-villeon-cream/80">
          Gestão de catálogo, estoque e compras.
        </p>
      </div>

      <div className="flex flex-1 items-center justify-center bg-background p-6 sm:p-10">
        <div className="w-full max-w-sm space-y-6">
          <div className="space-y-1 text-center lg:text-left">
            <h1 className="text-2xl font-semibold text-foreground">Entrar</h1>
            <p className="text-sm text-muted-foreground">
              Acesse com seu e-mail e senha cadastrados.
            </p>
          </div>
          <LoginForm />
        </div>
      </div>
    </div>
  );
}
