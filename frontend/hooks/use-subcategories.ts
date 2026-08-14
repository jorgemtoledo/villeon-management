"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchSubcategories } from "@/lib/api/subcategories";

// Subcategories essentially never change during a session — safe to treat
// as immutable data (no automatic refetch/staleness churn on every mount).
export function useSubcategories() {
  return useQuery({
    queryKey: ["subcategories"],
    queryFn: fetchSubcategories,
    staleTime: Infinity,
  });
}
