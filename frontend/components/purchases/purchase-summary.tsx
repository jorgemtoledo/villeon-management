import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency } from "@/lib/format-currency";
import { formatDate } from "@/lib/format-date";
import type { PurchaseDetail } from "@/types/purchase";

export function PurchaseSummary({ purchase }: { purchase: PurchaseDetail }) {
  return (
    <Card>
      <CardContent className="flex flex-col gap-4 px-4 sm:px-6">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Compra #{purchase.id}</h1>
          <p className="text-sm text-muted-foreground">
            {purchase.items.length} {purchase.items.length === 1 ? "item" : "itens"}
          </p>
        </div>
        <dl className="grid grid-cols-1 gap-x-6 gap-y-3 sm:grid-cols-2">
          <div>
            <dt className="text-sm text-muted-foreground">Fornecedor</dt>
            <dd className="text-foreground">{purchase.supplier.name}</dd>
          </div>
          <div>
            <dt className="text-sm text-muted-foreground">Data</dt>
            <dd className="text-foreground">{formatDate(purchase.purchased_at)}</dd>
          </div>
          <div>
            <dt className="text-sm text-muted-foreground">Total</dt>
            <dd className="text-foreground">{formatCurrency(purchase.total_amount)}</dd>
          </div>
          {purchase.invoice_number ? (
            <div>
              <dt className="text-sm text-muted-foreground">Nº da nota</dt>
              <dd className="text-foreground">{purchase.invoice_number}</dd>
            </div>
          ) : null}
        </dl>
      </CardContent>
    </Card>
  );
}
