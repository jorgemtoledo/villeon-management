"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { updateProductStockConfig } from "@/lib/api/product-stock";
import type { ProductStockConfigInput } from "@/types/product-stock";

export function useUpdateProductStockConfig(productId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: ProductStockConfigInput) => updateProductStockConfig(productId, input),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["product-stock", productId] }),
  });
}
