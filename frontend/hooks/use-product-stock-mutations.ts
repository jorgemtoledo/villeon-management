"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { updateProductStockConfig, updateProductStockPriority } from "@/lib/api/product-stock";
import type { ProductStockConfigInput, ProductStockPriorityInput } from "@/types/product-stock";

export function useUpdateProductStockConfig(productId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: ProductStockConfigInput) => updateProductStockConfig(productId, input),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["product-stock", productId] }),
  });
}

// Bloco 6G Parte 4 — separate endpoint/mutation from the admin-only config
// above: this one is sector-scoped and can be locked server-side once
// already set (see Ability#update_priority and the controller's
// locked_for_current_user? check). Invalidates the list too, not just the
// single-product query, since /estoque's table reads from the list.
export function useUpdateProductStockPriority(productId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: ProductStockPriorityInput) => updateProductStockPriority(productId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["product-stock", productId] });
      queryClient.invalidateQueries({ queryKey: ["product-stocks"] });
    },
  });
}
