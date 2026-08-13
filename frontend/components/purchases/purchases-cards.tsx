import Link from "next/link";

import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency } from "@/lib/format-currency";
import { formatDate } from "@/lib/format-date";
import type { Purchase } from "@/types/purchase";

// Mobile only (<md / 768px) — the whole card is a large tap target linking
// to the purchase's detail page.
export function PurchasesCards({ purchases }: { purchases: Purchase[] }) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {purchases.map((purchase) => (
        <Card key={purchase.id}>
          <CardContent className="px-4">
            <Link href={`/compras/${purchase.id}`} className="flex flex-col gap-2">
              <div className="flex items-start justify-between gap-2">
                <p className="font-medium text-foreground">{purchase.supplier.name}</p>
                <p className="font-medium text-foreground">{formatCurrency(purchase.total_amount)}</p>
              </div>
              <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
                <dt className="text-muted-foreground">Data</dt>
                <dd>{formatDate(purchase.purchased_at)}</dd>
                <dt className="text-muted-foreground">Itens</dt>
                <dd>{purchase.items_count}</dd>
              </dl>
            </Link>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
