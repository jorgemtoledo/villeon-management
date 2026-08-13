"use client";

import Link from "next/link";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { formatCnpj } from "@/lib/format-cnpj";
import { SupplierStatusActions } from "@/components/suppliers/supplier-status-actions";
import type { Supplier } from "@/types/supplier";

interface SuppliersCardsProps {
  suppliers: Supplier[];
  canManage: boolean;
  onEdit: (supplier: Supplier) => void;
}

// Mobile only (<md / 768px) — the whole card is a large tap target linking
// to the supplier's detail page, per the "ações grandes" mobile requirement.
export function SuppliersCards({ suppliers, canManage, onEdit }: SuppliersCardsProps) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {suppliers.map((supplier) => (
        <Card key={supplier.id}>
          <CardContent className="flex flex-col gap-3 px-4">
            <Link href={`/fornecedores/${supplier.id}`} className="flex flex-col gap-2">
              <div className="flex items-start justify-between gap-2">
                <p className="font-medium text-foreground">{supplier.name}</p>
                <Badge variant={supplier.active ? "default" : "secondary"}>
                  {supplier.active ? "Ativo" : "Inativo"}
                </Badge>
              </div>
              <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
                <dt className="text-muted-foreground">CNPJ</dt>
                <dd>{formatCnpj(supplier.cnpj)}</dd>
                <dt className="text-muted-foreground">Produtos vinculados</dt>
                <dd>{supplier.products_count}</dd>
              </dl>
            </Link>
            {canManage ? (
              <div className="pt-1">
                <SupplierStatusActions supplier={supplier} onEdit={() => onEdit(supplier)} />
              </div>
            ) : null}
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
