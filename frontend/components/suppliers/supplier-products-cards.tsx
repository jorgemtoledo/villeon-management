import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import type { SupplierProduct } from "@/types/supplier";

// Mobile only (<md / 768px) — see SupplierProductsTable for desktop/tablet.
export function SupplierProductsCards({ products }: { products: SupplierProduct[] }) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {products.map((product) => (
        <Card key={product.id}>
          <CardContent className="flex flex-col gap-2 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-medium text-foreground">{product.name}</p>
                <p className="text-xs text-muted-foreground">{product.code}</p>
              </div>
              {product.preferred ? <Badge>Preferido</Badge> : null}
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              <dt className="text-muted-foreground">Código do fornecedor</dt>
              <dd>{product.supplier_product_code ?? "—"}</dd>
              {product.notes ? (
                <>
                  <dt className="text-muted-foreground">Notas</dt>
                  <dd>{product.notes}</dd>
                </>
              ) : null}
            </dl>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
