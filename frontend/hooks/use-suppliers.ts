"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchSuppliers } from "@/lib/api/suppliers";
import type { SuppliersQuery } from "@/types/supplier";

export function useSuppliers(query: SuppliersQuery) {
  return useQuery({
    queryKey: ["suppliers", query],
    queryFn: () => fetchSuppliers(query),
    placeholderData: keepPreviousData,
  });
}
