"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { createPurchase, updatePurchase } from "@/lib/api/purchases";
import type { PurchaseInput } from "@/types/purchase";

export function useCreatePurchase() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: PurchaseInput) => createPurchase(input),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["purchases"] }),
  });
}

export function useUpdatePurchase(id: number | string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: PurchaseInput) => updatePurchase(id, input),
    // Both the list (["purchases", query]) and the detail (["purchases", id])
    // queries share the "purchases" prefix, so this one invalidation call
    // covers both — same as useCreatePurchase above.
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["purchases"] }),
  });
}
