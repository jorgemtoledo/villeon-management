"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createProductSupplier,
  deleteProductSupplier,
  preferProductSupplier,
} from "@/lib/api/product-suppliers";
import type { ProductSupplierInput } from "@/types/product-supplier";

function useInvalidateProductSuppliers(productId: number) {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ["product-suppliers", productId] });
}

export function useCreateProductSupplier(productId: number) {
  const invalidate = useInvalidateProductSuppliers(productId);

  return useMutation({
    mutationFn: (input: ProductSupplierInput) => createProductSupplier(productId, input),
    onSuccess: () => invalidate(),
  });
}

export function useDeleteProductSupplier(productId: number) {
  const invalidate = useInvalidateProductSuppliers(productId);

  return useMutation({
    mutationFn: (linkId: number) => deleteProductSupplier(productId, linkId),
    onSuccess: () => invalidate(),
  });
}

export function usePreferProductSupplier(productId: number) {
  const invalidate = useInvalidateProductSuppliers(productId);

  return useMutation({
    mutationFn: (linkId: number) => preferProductSupplier(productId, linkId),
    onSuccess: () => invalidate(),
  });
}
