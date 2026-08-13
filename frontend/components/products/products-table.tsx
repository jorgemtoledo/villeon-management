import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { ProductStatusActions } from "@/components/products/product-status-actions";
import type { Product } from "@/types/product";

interface ProductsTableProps {
  products: Product[];
  // Write actions (Editar/Ativar/Desativar) only render for admin — the API
  // already enforces this, this is purely presentational.
  canManage: boolean;
  onEdit: (product: Product) => void;
}

// Desktop/tablet only (≥md / 768px) — see ProductsCards for the mobile
// equivalent. Never resolved with just overflow-x-auto on a cramped table.
export function ProductsTable({ products, canManage, onEdit }: ProductsTableProps) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Produto</TableHead>
            <TableHead>Código</TableHead>
            <TableHead>Setor</TableHead>
            <TableHead>Unid. compra</TableHead>
            <TableHead>Unid. estoque</TableHead>
            <TableHead>Status</TableHead>
            {canManage ? <TableHead>Ações</TableHead> : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="font-medium">{product.name}</TableCell>
              <TableCell className="text-muted-foreground">{product.code}</TableCell>
              <TableCell>{product.sector?.name ?? "—"}</TableCell>
              <TableCell>{product.purchase_unit?.abbreviation ?? "—"}</TableCell>
              <TableCell>{product.stock_unit?.abbreviation ?? "—"}</TableCell>
              <TableCell>
                <Badge variant={product.active ? "default" : "secondary"}>
                  {product.active ? "Ativo" : "Inativo"}
                </Badge>
              </TableCell>
              {canManage ? (
                <TableCell>
                  <ProductStatusActions product={product} onEdit={() => onEdit(product)} />
                </TableCell>
              ) : null}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
