"use client";

import { useSyncExternalStore } from "react";

import { getServerSnapshot, getSnapshot, subscribe } from "@/lib/auth/session-store";

export function useSession() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}
