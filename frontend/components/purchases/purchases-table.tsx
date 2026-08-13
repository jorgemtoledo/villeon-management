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
import { formatCurrency } from "@/lib/format-currency";
import { formatDate } from "@/lib/format-date";
import type { Purchase } from "@/types/purchase";

// Desktop/tablet only (≥md / 768px) — see PurchasesCards for the mobile
// equivalent. Read-only: every row links to the purchase's detail page.
export function PurchasesTable({ purchases }: { purchases: Purchase[] }) {
  const router = useRouter();

  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Fornecedor</TableHead>
            <TableHead>Data</TableHead>
            <TableHead>Itens</TableHead>
            <TableHead>Total</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {purchases.map((purchase) => (
            <TableRow
              key={purchase.id}
              onClick={() => router.push(`/compras/${purchase.id}`)}
              className="cursor-pointer"
            >
              <TableCell className="font-medium">
                <Link href={`/compras/${purchase.id}`} className="hover:underline">
                  {purchase.supplier.name}
                </Link>
              </TableCell>
              <TableCell className="text-muted-foreground">{formatDate(purchase.purchased_at)}</TableCell>
              <TableCell>{purchase.items_count}</TableCell>
              <TableCell className="font-medium">{formatCurrency(purchase.total_amount)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
