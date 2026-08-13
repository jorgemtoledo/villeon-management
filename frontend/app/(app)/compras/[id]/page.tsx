"use client";

import { use } from "react";
import Link from "next/link";
import { ArrowLeft, Pencil } from "lucide-react";

import { usePurchase } from "@/hooks/use-purchase";
import { useAuth } from "@/hooks/use-auth";
import { canManagePurchases } from "@/lib/auth/permissions";
import { ApiError } from "@/lib/api/client";
import { Button } from "@/components/ui/button";
import { PurchaseSummary } from "@/components/purchases/purchase-summary";
import { PurchaseItemsTable } from "@/components/purchases/purchase-items-table";
import { PurchaseItemsCards } from "@/components/purchases/purchase-items-cards";
import {
  PurchaseDetailErrorState,
  PurchaseDetailLoadingState,
  PurchaseNotFoundState,
} from "@/components/purchases/purchase-detail-states";

export default function CompraDetalhePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const purchaseQuery = usePurchase(id);
  const { user } = useAuth();
  const canManage = canManagePurchases(user);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Link
          href="/compras"
          className="inline-flex w-fit items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          Voltar para compras
        </Link>
        {canManage && purchaseQuery.data ? (
          <Button
            type="button"
            variant="outline"
            className="h-11 md:h-9"
            nativeButton={false}
            render={<Link href={`/compras/${id}/editar`} />}
          >
            <Pencil className="size-4" />
            Editar compra
          </Button>
        ) : null}
      </div>

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
          <PurchaseSummary purchase={purchaseQuery.data} />

          <div className="flex flex-col gap-4">
            <h2 className="text-lg font-semibold text-foreground">Itens</h2>
            <PurchaseItemsTable items={purchaseQuery.data.items} />
            <PurchaseItemsCards items={purchaseQuery.data.items} />
          </div>
        </>
      ) : null}
    </div>
  );
}
