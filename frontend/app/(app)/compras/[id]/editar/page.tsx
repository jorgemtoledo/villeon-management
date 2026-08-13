"use client";

import { use } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";

import { useAuth } from "@/hooks/use-auth";
import { canManagePurchases } from "@/lib/auth/permissions";
import { usePurchase } from "@/hooks/use-purchase";
import { useUpdatePurchase } from "@/hooks/use-purchase-mutations";
import { ApiError } from "@/lib/api/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { PurchaseForm } from "@/components/purchases/purchase-form";
import {
  PurchaseDetailErrorState,
  PurchaseDetailLoadingState,
  PurchaseFormForbiddenState,
  PurchaseNotFoundState,
} from "@/components/purchases/purchase-detail-states";
import type { PurchaseInput } from "@/types/purchase";

const FORM_ID = "purchase-form";

export default function EditarCompraPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { user } = useAuth();
  const canManage = canManagePurchases(user);
  const router = useRouter();

  // Page-level guard, same pattern as /compras/nova and /usuarios: the real
  // protection is the backend's 403 (Ability#update on Purchase), this just
  // avoids fetching/rendering a form an operator could never submit.
  const purchaseQuery = usePurchase(canManage ? id : undefined);
  const mutation = useUpdatePurchase(id);

  if (!canManage) {
    return <PurchaseFormForbiddenState backHref={`/compras/${id}`} />;
  }

  function handleSubmit(input: PurchaseInput) {
    mutation.mutate(input, {
      onSuccess: () => {
        toast.success("Compra atualizada com sucesso.");
        router.push(`/compras/${id}`);
      },
    });
  }

  const error = mutation.error;
  const errorMessage = error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar a compra." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <div className="flex flex-col gap-4">
      <Link
        href={`/compras/${id}`}
        className="inline-flex w-fit items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        Voltar para a compra
      </Link>

      {purchaseQuery.isPending ? <PurchaseDetailLoadingState /> : null}

      {purchaseQuery.isError ? (
        purchaseQuery.error instanceof ApiError && purchaseQuery.error.status === 404 ? (
          <PurchaseNotFoundState />
        ) : (
          <PurchaseDetailErrorState onRetry={() => purchaseQuery.refetch()} />
        )
      ) : null}

      {purchaseQuery.data ? (
        <>
          <div>
            <h1 className="text-xl font-semibold text-foreground">Editar compra #{purchaseQuery.data.id}</h1>
            <p className="text-sm text-muted-foreground">
              Altere os dados da compra e seus itens. O total é sempre recalculado pelo sistema.
            </p>
          </div>

          <Card>
            <CardContent className="px-4 sm:px-6">
              <PurchaseForm
                formId={FORM_ID}
                purchase={purchaseQuery.data}
                onSubmit={handleSubmit}
                errorMessage={errorMessage}
                errorDetails={errorDetails}
              />
            </CardContent>
          </Card>

          <div className="flex justify-end gap-2 pb-2">
            <Button
              type="button"
              variant="outline"
              className="h-11 md:h-9"
              nativeButton={false}
              render={<Link href={`/compras/${id}`} />}
            >
              Cancelar
            </Button>
            <Button type="submit" form={FORM_ID} disabled={mutation.isPending} className="h-11 md:h-9">
              {mutation.isPending ? "Salvando..." : "Salvar alterações"}
            </Button>
          </div>
        </>
      ) : null}
    </div>
  );
}
