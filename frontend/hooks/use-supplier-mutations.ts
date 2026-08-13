"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  activateSupplier,
  createSupplier,
  deactivateSupplier,
  updateSupplier,
} from "@/lib/api/suppliers";
import type { SupplierInput } from "@/types/supplier";

// Invalidating the ["suppliers"] prefix covers the list (["suppliers", query]),
// the detail (["suppliers", id]) and the linked-products query
// (["suppliers", id, "products", query]) in one call — TanStack Query matches
// by key prefix, so there's no need to invalidate each one separately.
function useInvalidateSuppliers() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ["suppliers"] });
}

export function useCreateSupplier() {
  const invalidate = useInvalidateSuppliers();

  return useMutation({
    mutationFn: (input: SupplierInput) => createSupplier(input),
    onSuccess: () => invalidate(),
  });
}

export function useUpdateSupplier(id: number) {
  const invalidate = useInvalidateSuppliers();

  return useMutation({
    mutationFn: (input: SupplierInput) => updateSupplier(id, input),
    onSuccess: () => invalidate(),
  });
}

export function useActivateSupplier() {
  const invalidate = useInvalidateSuppliers();

  return useMutation({
    mutationFn: (id: number) => activateSupplier(id),
    onSuccess: () => invalidate(),
  });
}

export function useDeactivateSupplier() {
  const invalidate = useInvalidateSuppliers();

  return useMutation({
    mutationFn: (id: number) => deactivateSupplier(id),
    onSuccess: () => invalidate(),
  });
}
