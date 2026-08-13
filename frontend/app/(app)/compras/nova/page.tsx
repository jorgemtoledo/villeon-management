"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";

import { useAuth } from "@/hooks/use-auth";
import { canManagePurchases } from "@/lib/auth/permissions";
import { useCreatePurchase } from "@/hooks/use-purchase-mutations";
import { ApiError } from "@/lib/api/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { PurchaseForm } from "@/components/purchases/purchase-form";
import { PurchaseFormForbiddenState } from "@/components/purchases/purchase-detail-states";
import type { PurchaseInput } from "@/types/purchase";

const FORM_ID = "purchase-form";

export default function NovaCompraPage() {
  const { user } = useAuth();
  const canCreate = canManagePurchases(user);
  const router = useRouter();
  const mutation = useCreatePurchase();

  // Page-level guard, same pattern as /usuarios: the real protection is the
  // backend's 403 (Ability#create on Purchase), this just avoids rendering a
  // form an operator/no-permission user could never actually submit.
  if (!canCreate) {
    return <PurchaseFormForbiddenState />;
  }

  function handleSubmit(input: PurchaseInput) {
    mutation.mutate(input, {
      onSuccess: (purchase) => {
        toast.success("Compra registrada com sucesso.");
        router.push(`/compras/${purchase.id}`);
      },
    });
  }

  const error = mutation.error;
  const errorMessage = error instanceof ApiError ? error.message : error ? "Erro inesperado ao registrar a compra." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <div className="flex flex-col gap-4">
      <Link
        href="/compras"
        className="inline-flex w-fit items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        Voltar para compras
      </Link>

      <div>
        <h1 className="text-xl font-semibold text-foreground">Nova compra</h1>
        <p className="text-sm text-muted-foreground">
          Registre uma compra e seus itens. O total é sempre calculado pelo sistema.
        </p>
      </div>

      <Card>
        <CardContent className="px-4 sm:px-6">
          <PurchaseForm
            formId={FORM_ID}
            onSubmit={handleSubmit}
            errorMessage={errorMessage}
            errorDetails={errorDetails}
          />
        </CardContent>
      </Card>

      <div className="flex justify-end gap-2 pb-2">
        <Button type="button" variant="outline" className="h-11 md:h-9" nativeButton={false} render={<Link href="/compras" />}>
          Cancelar
        </Button>
        <Button type="submit" form={FORM_ID} disabled={mutation.isPending} className="h-11 md:h-9">
          {mutation.isPending ? "Registrando..." : "Registrar compra"}
        </Button>
      </div>
    </div>
  );
}
