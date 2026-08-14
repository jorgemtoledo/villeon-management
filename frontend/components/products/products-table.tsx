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
import { ProductSuppliersCell } from "@/components/products/product-suppliers-cell";
import type { Product } from "@/types/product";

interface ProductsTableProps {
  products: Product[];
  // Write actions (Editar/Ativar/Desativar) only render for admin — the API
  // already enforces this, this is purely presentational.
  canManage: boolean;
  // Opens the sheet. Called on row click for every role (Bloco 6I.1: manager/
  // operator can now view — read-only — the same sheet, including the
  // suppliers section); the Ações column below is a separate admin-only
  // shortcut into the same handler, not a different one.
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
            <TableHead>Fornecedores</TableHead>
            <TableHead>Status</TableHead>
            {canManage ? <TableHead>Ações</TableHead> : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id} onClick={() => onEdit(product)} className="cursor-pointer">
              <TableCell className="font-medium">{product.name}</TableCell>
              <TableCell className="text-muted-foreground">{product.code}</TableCell>
              <TableCell>{product.sector?.name ?? "—"}</TableCell>
              <TableCell>{product.purchase_unit?.abbreviation ?? "—"}</TableCell>
              <TableCell>{product.stock_unit?.abbreviation ?? "—"}</TableCell>
              <TableCell onClick={(event) => event.stopPropagation()}>
                <ProductSuppliersCell productId={product.id} count={product.product_suppliers_count} />
              </TableCell>
              <TableCell>
                <Badge variant={product.active ? "default" : "secondary"}>
                  {product.active ? "Ativo" : "Inativo"}
                </Badge>
              </TableCell>
              {canManage ? (
                <TableCell onClick={(event) => event.stopPropagation()}>
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
