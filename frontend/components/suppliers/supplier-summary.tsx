import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { formatCnpj } from "@/lib/format-cnpj";
import type { Supplier } from "@/types/supplier";

export function SupplierSummary({ supplier }: { supplier: Supplier }) {
  return (
    <Card>
      <CardContent className="flex flex-col gap-4 px-4 sm:px-6">
        <div className="flex flex-wrap items-start justify-between gap-2">
          <h1 className="text-xl font-semibold text-foreground">{supplier.name}</h1>
          <Badge variant={supplier.active ? "default" : "secondary"}>
            {supplier.active ? "Ativo" : "Inativo"}
          </Badge>
        </div>
        <dl className="grid grid-cols-1 gap-x-6 gap-y-3 sm:grid-cols-2">
          <div>
            <dt className="text-sm text-muted-foreground">CNPJ</dt>
            <dd className="text-foreground">{formatCnpj(supplier.cnpj)}</dd>
          </div>
          <div>
            <dt className="text-sm text-muted-foreground">Produtos vinculados</dt>
            <dd className="text-foreground">{supplier.products_count}</dd>
          </div>
        </dl>
      </CardContent>
    </Card>
  );
}
