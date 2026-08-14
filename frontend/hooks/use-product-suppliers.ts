"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchProductSuppliers } from "@/lib/api/product-suppliers";

// enabled: false while the sheet is closed or in create mode (no product id
// yet) — same enabled-gating pattern as useProductStock.
export function useProductSuppliers(productId: number | undefined) {
  return useQuery({
    queryKey: ["product-suppliers", productId],
    queryFn: () => fetchProductSuppliers(productId as number),
    enabled: productId !== undefined,
  });
}
