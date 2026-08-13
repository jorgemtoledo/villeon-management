"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchProducts } from "@/lib/api/products";
import type { ProductsQuery } from "@/types/product";

export function useProducts(query: ProductsQuery) {
  return useQuery({
    queryKey: ["products", query],
    queryFn: () => fetchProducts(query),
    placeholderData: keepPreviousData,
  });
}
