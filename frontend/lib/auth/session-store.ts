import type { AuthUser } from "@/types/auth";

// Framework-agnostic external store (React 19's useSyncExternalStore contract)
// for the JWT session. Lives outside React so lib/api/client.ts can read the
// current token without importing React or drilling context through every
// fetcher. The JWT is kept in localStorage only to survive a page refresh —
// never in a cookie, matching the explicit Bearer-header requirement.
export type SessionStatus = "idle" | "authenticated" | "unauthenticated";

export interface SessionState {
  token: string | null;
  user: AuthUser | null;
  status: SessionStatus;
}

const STORAGE_KEY = "villeon.auth.token";

function readStoredToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(STORAGE_KEY);
}

let state: SessionState = {
  token: readStoredToken(),
  user: null,
  status: "idle",
};

const serverState: SessionState = { token: null, user: null, status: "idle" };

const listeners = new Set<() => void>();

function emit() {
  listeners.forEach((listener) => listener());
}

export function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getSnapshot(): SessionState {
  return state;
}

// useSyncExternalStore uses this during SSR and during hydration's first
// client render, so the initial render never depends on localStorage —
// avoids a hydration mismatch even though `state` above is already
// populated from localStorage by the time components mount.
export function getServerSnapshot(): SessionState {
  return serverState;
}

export function getToken(): string | null {
  return state.token;
}

export function setSession(token: string, user: AuthUser): void {
  state = { token, user, status: "authenticated" };
  if (typeof window !== "undefined") {
    window.localStorage.setItem(STORAGE_KEY, token);
  }
  emit();
}

export function setUser(user: AuthUser): void {
  state = { ...state, user, status: "authenticated" };
  emit();
}

export function clearSession(): void {
  if (state.token === null && state.status === "unauthenticated") return;
  state = { token: null, user: null, status: "unauthenticated" };
  if (typeof window !== "undefined") {
    window.localStorage.removeItem(STORAGE_KEY);
  }
  emit();
}

export function markUnauthenticated(): void {
  clearSession();
}
