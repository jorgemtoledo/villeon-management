import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { formatCurrency } from "@/lib/format-currency";
import type { PurchaseItem } from "@/types/purchase";

// Desktop/tablet only (≥md / 768px) — see PurchaseItemsCards for mobile.
export function PurchaseItemsTable({ items }: { items: PurchaseItem[] }) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Produto</TableHead>
            <TableHead>Código</TableHead>
            <TableHead>Quantidade</TableHead>
            <TableHead>Unidade</TableHead>
            <TableHead>Preço unitário</TableHead>
            <TableHead>Total</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {items.map((item) => (
            <TableRow key={item.id}>
              <TableCell className="font-medium">{item.product.name}</TableCell>
              <TableCell className="text-muted-foreground">{item.product.code}</TableCell>
              <TableCell>{Number(item.quantity).toLocaleString("pt-BR")}</TableCell>
              <TableCell>{item.unit?.abbreviation ?? "—"}</TableCell>
              <TableCell>{formatCurrency(item.unit_price)}</TableCell>
              <TableCell className="font-medium">{formatCurrency(item.total_price)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
