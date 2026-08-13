"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchPurchases } from "@/lib/api/purchases";
import type { PurchasesQuery } from "@/types/purchase";

export function usePurchases(query: PurchasesQuery) {
  return useQuery({
    queryKey: ["purchases", query],
    queryFn: () => fetchPurchases(query),
    placeholderData: keepPreviousData,
  });
}
