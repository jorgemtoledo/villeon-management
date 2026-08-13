"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  activateProduct,
  createProduct,
  deactivateProduct,
  updateProduct,
} from "@/lib/api/products";
import type { ProductInput } from "@/types/product";

// All four mutations invalidate the same ["products"] key on success — this
// matches every list-query variant (any filter/page/sort combination) so the
// list always reflects the change, regardless of which page/filter the user
// was on. There's no ["products", id] query today (no product detail view),
// so there's nothing else to invalidate.
function useInvalidateProducts() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ["products"] });
}

export function useCreateProduct() {
  const invalidate = useInvalidateProducts();

  return useMutation({
    mutationFn: (input: ProductInput) => createProduct(input),
    onSuccess: () => invalidate(),
  });
}

export function useUpdateProduct(id: number) {
  const invalidate = useInvalidateProducts();

  return useMutation({
    mutationFn: (input: ProductInput) => updateProduct(id, input),
    onSuccess: () => invalidate(),
  });
}

export function useActivateProduct() {
  const invalidate = useInvalidateProducts();

  return useMutation({
    mutationFn: (id: number) => activateProduct(id),
    onSuccess: () => invalidate(),
  });
}

export function useDeactivateProduct() {
  const invalidate = useInvalidateProducts();

  return useMutation({
    mutationFn: (id: number) => deactivateProduct(id),
    onSuccess: () => invalidate(),
  });
}
