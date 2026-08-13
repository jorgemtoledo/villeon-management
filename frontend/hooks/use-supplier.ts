"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchSupplier } from "@/lib/api/suppliers";

export function useSupplier(id: number | string | undefined) {
  return useQuery({
    queryKey: ["suppliers", id],
    queryFn: () => fetchSupplier(id as number | string),
    enabled: id !== undefined,
  });
}
