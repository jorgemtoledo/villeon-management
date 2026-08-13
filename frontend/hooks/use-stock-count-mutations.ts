"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { createStockCount } from "@/lib/api/stock-counts";
import type { StockCountInput } from "@/types/stock-count";

// "Registrar" and "atualizar" a count are the same call here (POST) — see
// the Bloco 6G Parte 3 report: the list/show payload never exposes a
// StockCount id to PATCH against (only the derived current_quantity), and a
// fresh count always supersedes the previous one by counted_at anyway
// (StockCount#sync_product_stock!), so resubmitting has the same effect as
// "editing" the count for this operational screen's purposes.
export function useCreateStockCount(productId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: StockCountInput) => createStockCount(productId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [ "product-stocks" ] });
      queryClient.invalidateQueries({ queryKey: [ "product-stock", productId ] });
    },
  });
}
