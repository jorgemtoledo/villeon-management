"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchProductStock } from "@/lib/api/product-stock";

// enabled: false while the sheet is closed or in create mode (no product id
// yet) — mirrors the enabled-gating pattern used by useUsers for non-admins.
export function useProductStock(productId: number | undefined) {
  return useQuery({
    queryKey: ["product-stock", productId],
    queryFn: () => fetchProductStock(productId as number),
    enabled: productId !== undefined,
  });
}
