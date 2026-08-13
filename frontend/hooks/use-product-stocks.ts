"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchProductStocks } from "@/lib/api/product-stock";
import type { ProductStocksQuery } from "@/types/product-stock";

// Plural — the sector-scoped operational list (/estoque). Disabled until a
// sector is actually selected: a user with no allowed sectors should never
// fire this request at all (the page shows StockNoSectorState instead).
export function useProductStocks(query: ProductStocksQuery) {
  return useQuery({
    queryKey: [ "product-stocks", query ],
    queryFn: () => fetchProductStocks(query),
    placeholderData: keepPreviousData,
    enabled: query.sectorId !== undefined,
  });
}
