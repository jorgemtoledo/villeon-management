"use client";

import { useEffect, useRef } from "react";

import { fetchMe } from "@/lib/api/auth";
import { clearSession, getSnapshot, setUser } from "@/lib/auth/session-store";

// Renders nothing — on mount, if a token survived from a previous visit
// (localStorage), validates it against GET /api/v1/me and hydrates the user;
// otherwise marks the session unauthenticated. Runs once per full page load.
//
// Deliberately reads getSnapshot() imperatively here instead of the
// useSession() hook. useSyncExternalStore renders the *first* hydration pass
// with getServerSnapshot (token: null) to match the static HTML, then
// corrects itself on a follow-up render — but effects fire on every commit,
// including that first one. Depending on the hook's `token` meant this
// effect could run once with the still-null hydration value, treat it as
// "no session", and call clearSession() — wiping the real token before the
// corrected render ever happened. Reading the store directly in the effect
// (which only ever runs client-side, after the real module state is live)
// avoids that race entirely.
export function AuthBootstrap() {
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current) return;
    ran.current = true;

    const { token, status } = getSnapshot();
    if (status !== "idle") return;

    if (!token) {
      clearSession();
      return;
    }

    fetchMe()
      .then((user) => setUser(user))
      .catch(() => clearSession());
  }, []);

  return null;
}
