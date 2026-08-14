"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchProductStockAuditEntries, fetchStockAuditEntries } from "@/lib/api/stock-audit";
import type { StockAuditEntriesQuery } from "@/types/stock-audit";

export function useStockAuditEntries(query: StockAuditEntriesQuery, options: { enabled?: boolean } = {}) {
  return useQuery({
    queryKey: ["stock-audit-entries", query],
    queryFn: () => fetchStockAuditEntries(query),
    placeholderData: keepPreviousData,
    enabled: options.enabled ?? true,
  });
}

export function useProductStockAuditEntries(
  productId: number | undefined,
  query: StockAuditEntriesQuery = {},
  options: { enabled?: boolean } = {},
) {
  return useQuery({
    queryKey: ["product-stock-audit-entries", productId, query],
    queryFn: () => fetchProductStockAuditEntries(productId as number, query),
    placeholderData: keepPreviousData,
    enabled: (options.enabled ?? true) && productId !== undefined,
  });
}
