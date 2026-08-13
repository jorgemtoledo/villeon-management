"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchUnits } from "@/lib/api/units";

// Units essentially never change during a session — safe to treat as
// immutable data (no automatic refetch/staleness churn on every mount).
export function useUnits() {
  return useQuery({
    queryKey: ["units"],
    queryFn: fetchUnits,
    staleTime: Infinity,
  });
}
