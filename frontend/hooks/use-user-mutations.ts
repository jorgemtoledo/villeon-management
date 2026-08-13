"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { activateUser, createUser, deactivateUser, updateUser } from "@/lib/api/users";
import type { UserInput } from "@/types/user";

// Same pattern as use-product-mutations.ts: every mutation invalidates the
// whole ["users"] key so any list/filter/page combination stays correct.
function useInvalidateUsers() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ["users"] });
}

export function useCreateUser() {
  const invalidate = useInvalidateUsers();

  return useMutation({
    mutationFn: (input: UserInput) => createUser(input),
    onSuccess: () => invalidate(),
  });
}

export function useUpdateUser(id: number) {
  const invalidate = useInvalidateUsers();

  return useMutation({
    mutationFn: (input: UserInput) => updateUser(id, input),
    onSuccess: () => invalidate(),
  });
}

export function useActivateUser() {
  const invalidate = useInvalidateUsers();

  return useMutation({
    mutationFn: (id: number) => activateUser(id),
    onSuccess: () => invalidate(),
  });
}

export function useDeactivateUser() {
  const invalidate = useInvalidateUsers();

  return useMutation({
    mutationFn: (id: number) => deactivateUser(id),
    onSuccess: () => invalidate(),
  });
}
