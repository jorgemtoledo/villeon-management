"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { fetchUsers } from "@/lib/api/users";
import type { UsersQuery } from "@/types/user";

// `enabled` defaults to true — callers that need to gate the request on a
// frontend-only permission check (e.g. /usuarios' page-level admin guard)
// pass `enabled: false` so the request is never fired at all, not just
// hidden after a 403.
export function useUsers(query: UsersQuery, options: { enabled?: boolean } = {}) {
  return useQuery({
    queryKey: ["users", query],
    queryFn: () => fetchUsers(query),
    placeholderData: keepPreviousData,
    enabled: options.enabled ?? true,
  });
}
