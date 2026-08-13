"use client";

import { use, useState } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

import { useSupplier } from "@/hooks/use-supplier";
import { useSupplierProducts } from "@/hooks/use-supplier-products";
import { useAuth } from "@/hooks/use-auth";
import { canManageSuppliers } from "@/lib/auth/permissions";
import { ApiError } from "@/lib/api/client";
import { Pagination } from "@/components/shared/pagination";
import { SupplierSummary } from "@/components/suppliers/supplier-summary";
import { SupplierStatusActions } from "@/components/suppliers/supplier-status-actions";
import { SupplierFormSheet } from "@/components/suppliers/supplier-form-sheet";
import { SupplierProductsTable } from "@/components/suppliers/supplier-products-table";
import { SupplierProductsCards } from "@/components/suppliers/supplier-products-cards";
import {
  SupplierProductsEmptyState,
  SupplierProductsErrorState,
  SupplierProductsLoadingState,
} from "@/components/suppliers/supplier-products-states";
import {
  SupplierDetailErrorState,
  SupplierDetailLoadingState,
  SupplierNotFoundState,
} from "@/components/suppliers/supplier-detail-states";

const PER_PAGE = 25;

export default function FornecedorDetalhePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { user } = useAuth();
  const canManage = canManageSuppliers(user);

  const [productsPage, setProductsPage] = useState(1);
  const [isEditing, setIsEditing] = useState(false);

  const supplierQuery = useSupplier(id);
  const productsQuery = useSupplierProducts(id, { page: productsPage, perPage: PER_PAGE });

  return (
    <div className="flex flex-col gap-4">
      <Link
        href="/fornecedores"
        className="inline-flex w-fit items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        Voltar para fornecedores
      </Link>

      {supplierQuery.isPending ? <SupplierDetailLoadingState /> : null}

      {supplierQuery.isError ? (
        supplierQuery.error instanceof ApiError && supplierQuery.error.status === 404 ? (
          <SupplierNotFoundState />
        ) : (
          <SupplierDetailErrorState onRetry={() => supplierQuery.refetch()} />
        )
      ) : null}

      {supplierQuery.data ? (
        <>
          <SupplierSummary supplier={supplierQuery.data} />

          {canManage ? (
            <SupplierStatusActions supplier={supplierQuery.data} onEdit={() => setIsEditing(true)} />
          ) : null}

          <div className="flex flex-col gap-4">
            <h2 className="text-lg font-semibold text-foreground">Produtos vinculados</h2>

            {productsQuery.isPending ? <SupplierProductsLoadingState /> : null}

            {productsQuery.isError ? (
              <SupplierProductsErrorState onRetry={() => productsQuery.refetch()} />
            ) : null}

            {!productsQuery.isPending && !productsQuery.isError && productsQuery.data ? (
              productsQuery.data.data.length === 0 ? (
                <SupplierProductsEmptyState />
              ) : (
                <div className={productsQuery.isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
                  <SupplierProductsTable products={productsQuery.data.data} />
                  <SupplierProductsCards products={productsQuery.data.data} />
                  <Pagination meta={productsQuery.data.meta} onPageChange={setProductsPage} itemLabel="produtos" />
                </div>
              )
            ) : null}
          </div>

          {canManage ? (
            <SupplierFormSheet open={isEditing} onOpenChange={setIsEditing} supplier={supplierQuery.data} />
          ) : null}
        </>
      ) : null}
    </div>
  );
}
