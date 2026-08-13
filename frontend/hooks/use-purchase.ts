"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchPurchase } from "@/lib/api/purchases";

export function usePurchase(id: number | string | undefined) {
  return useQuery({
    queryKey: ["purchases", id],
    queryFn: () => fetchPurchase(id as number | string),
    enabled: id !== undefined,
  });
}
