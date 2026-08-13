"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchSupplierProducts } from "@/lib/api/suppliers";
import type { SupplierProductsQuery } from "@/types/supplier";

// Only ever called from the supplier detail page — the suppliers list never
// fetches this, so listing 101 suppliers never triggers 101 extra requests.
export function useSupplierProducts(id: number | string | undefined, query: SupplierProductsQuery) {
  return useQuery({
    queryKey: ["suppliers", id, "products", query],
    queryFn: () => fetchSupplierProducts(id as number | string, query),
    enabled: id !== undefined,
    placeholderData: keepPreviousData,
  });
}
