import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import type { SupplierProduct } from "@/types/supplier";

// Desktop/tablet only (≥md / 768px) — see SupplierProductsCards for mobile.
// Read-only: no link to Product, no edit affordance (Bloco 6A is read-only).
export function SupplierProductsTable({ products }: { products: SupplierProduct[] }) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Produto</TableHead>
            <TableHead>Código</TableHead>
            <TableHead>Código do fornecedor</TableHead>
            <TableHead>Preferido</TableHead>
            <TableHead>Notas</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="font-medium">{product.name}</TableCell>
              <TableCell className="text-muted-foreground">{product.code}</TableCell>
              <TableCell>{product.supplier_product_code ?? "—"}</TableCell>
              <TableCell>
                {product.preferred ? <Badge>Preferido</Badge> : <span className="text-muted-foreground">—</span>}
              </TableCell>
              <TableCell className="text-muted-foreground">{product.notes ?? "—"}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
