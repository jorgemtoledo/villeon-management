import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { ProductStatusActions } from "@/components/products/product-status-actions";
import type { Product } from "@/types/product";

interface ProductsCardsProps {
  products: Product[];
  canManage: boolean;
  onEdit: (product: Product) => void;
}

// Mobile only (<md / 768px) — a table with 6+ columns doesn't fit a phone
// screen without horizontal scroll, so it becomes a stacked card list here
// instead of the ProductsTable used on md+.
export function ProductsCards({ products, canManage, onEdit }: ProductsCardsProps) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {products.map((product) => (
        <Card key={product.id}>
          <CardContent className="flex flex-col gap-3 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-medium text-foreground">{product.name}</p>
                <p className="text-xs text-muted-foreground">{product.code}</p>
              </div>
              <Badge variant={product.active ? "default" : "secondary"}>
                {product.active ? "Ativo" : "Inativo"}
              </Badge>
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              <dt className="text-muted-foreground">Setor</dt>
              <dd>{product.sector?.name ?? "—"}</dd>
              <dt className="text-muted-foreground">Unid. compra</dt>
              <dd>{product.purchase_unit?.abbreviation ?? "—"}</dd>
              <dt className="text-muted-foreground">Unid. estoque</dt>
              <dd>{product.stock_unit?.abbreviation ?? "—"}</dd>
            </dl>
            {canManage ? (
              <div className="pt-1">
                <ProductStatusActions product={product} onEdit={() => onEdit(product)} />
              </div>
            ) : null}
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
