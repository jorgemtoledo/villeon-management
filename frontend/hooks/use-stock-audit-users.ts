"use client";

import { useQuery } from "@tanstack/react-query";

import { fetchStockAuditUsers } from "@/lib/api/stock-audit";

// Only used to populate the "Usuário" filter select on the Histórico screen
// — same immutable-enough-to-cache reasoning as useUnits/useSubcategories.
export function useStockAuditUsers(options: { enabled?: boolean } = {}) {
  return useQuery({
    queryKey: ["stock-audit-users"],
    queryFn: fetchStockAuditUsers,
    staleTime: Infinity,
    enabled: options.enabled ?? true,
  });
}
