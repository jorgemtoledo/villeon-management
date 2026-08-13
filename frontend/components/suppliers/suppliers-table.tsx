"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { formatCnpj } from "@/lib/format-cnpj";
import { SupplierStatusActions } from "@/components/suppliers/supplier-status-actions";
import type { Supplier } from "@/types/supplier";

interface SuppliersTableProps {
  suppliers: Supplier[];
  // Write actions (Editar/Ativar/Desativar) only render for admin — the API
  // already enforces this, this is purely presentational.
  canManage: boolean;
  onEdit: (supplier: Supplier) => void;
}

// Desktop/tablet only (≥md / 768px) — see SuppliersCards for the mobile
// equivalent. Never resolved with just overflow-x-auto on a cramped table.
export function SuppliersTable({ suppliers, canManage, onEdit }: SuppliersTableProps) {
  const router = useRouter();

  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Fornecedor</TableHead>
            <TableHead>CNPJ</TableHead>
            <TableHead>Produtos vinculados</TableHead>
            <TableHead>Status</TableHead>
            {canManage ? <TableHead>Ações</TableHead> : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {suppliers.map((supplier) => (
            <TableRow
              key={supplier.id}
              onClick={() => router.push(`/fornecedores/${supplier.id}`)}
              className="cursor-pointer"
            >
              <TableCell className="font-medium">
                <Link href={`/fornecedores/${supplier.id}`} className="hover:underline">
                  {supplier.name}
                </Link>
              </TableCell>
              <TableCell className="text-muted-foreground">{formatCnpj(supplier.cnpj)}</TableCell>
              <TableCell>{supplier.products_count}</TableCell>
              <TableCell>
                <Badge variant={supplier.active ? "default" : "secondary"}>
                  {supplier.active ? "Ativo" : "Inativo"}
                </Badge>
              </TableCell>
              {canManage ? (
                <TableCell onClick={(event) => event.stopPropagation()}>
                  <SupplierStatusActions supplier={supplier} onEdit={() => onEdit(supplier)} />
                </TableCell>
              ) : null}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
