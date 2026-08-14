"use client";

import { Truck } from "lucide-react";

import { useProductSuppliers } from "@/hooks/use-product-suppliers";
import { Badge } from "@/components/ui/badge";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Skeleton } from "@/components/ui/skeleton";

interface ProductSuppliersCellProps {
  productId: number;
  count: number;
}

// Used in both ProductsTable and ProductsCards. 0 = "A definir" in red, no
// popover — there's nothing to show. Otherwise the count opens a popover
// that fetches the actual list lazily (only once opened, via the same
// useProductSuppliers hook the edit sheet already uses) instead of loading
// every row's full supplier list up front just to show a number.
export function ProductSuppliersCell({ productId, count }: ProductSuppliersCellProps) {
  if (count === 0) {
    return <span className="text-sm font-medium text-destructive">A definir</span>;
  }

  return (
    <Popover>
      <PopoverTrigger
        render={
          <button
            type="button"
            className="cursor-pointer appearance-none rounded-4xl border-0 bg-transparent p-0 outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          />
        }
      >
        <Badge variant="outline">
          <Truck data-icon="inline-start" />
          {count}
        </Badge>
      </PopoverTrigger>
      <PopoverContent>
        <ProductSuppliersPopoverList productId={productId} />
      </PopoverContent>
    </Popover>
  );
}

function ProductSuppliersPopoverList({ productId }: { productId: number }) {
  const { data, isPending, isError } = useProductSuppliers(productId);

  if (isPending) {
    return (
      <div className="flex flex-col gap-2">
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-2/3" />
      </div>
    );
  }

  if (isError || !data) {
    return <p className="text-muted-foreground">Não foi possível carregar os fornecedores.</p>;
  }

  return (
    <ul className="flex flex-col gap-1.5">
      {data.map((link) => (
        <li key={link.id} className="flex items-center justify-between gap-2">
          <span className="text-foreground">{link.supplier.name}</span>
          {link.preferred ? <Badge>Principal</Badge> : null}
        </li>
      ))}
    </ul>
  );
}
