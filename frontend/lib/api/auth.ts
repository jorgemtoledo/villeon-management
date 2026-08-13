import { API_URL } from "@/lib/env";
import { apiRequest, ApiError } from "@/lib/api/client";
import { clearSession } from "@/lib/auth/session-store";
import type { AuthUser } from "@/types/auth";

interface LoginResult {
  token: string;
  user: AuthUser;
}

// Devise's SessionsController never puts the token in the JSON body — only
// in the Authorization response header (devise-jwt convention) — so this
// bypasses apiRequest (which is for already-authenticated calls) and reads
// the header directly. Requires the backend's CORS `expose: ["Authorization"]`
// (see backend/config/initializers/cors.rb) or the browser can't see it.
export async function login(email: string, password: string): Promise<LoginResult> {
  const response = await fetch(`${API_URL}/api/v1/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ user: { email, password } }),
  });

  const body = await response.json().catch(() => null);

  if (!response.ok) {
    throw new ApiError(response.status, body?.error ?? "E-mail ou senha inválidos.");
  }

  const authHeader = response.headers.get("Authorization");
  const token = authHeader?.replace(/^Bearer\s+/i, "");

  if (!token || !body?.user) {
    throw new ApiError(500, "Resposta de login incompleta do servidor.");
  }

  return { token, user: body.user as AuthUser };
}

export async function logout(): Promise<void> {
  try {
    await apiRequest("/api/v1/logout", { method: "DELETE" });
  } finally {
    // Always clear locally, even if the network call failed — the user must
    // always be able to log out client-side.
    clearSession();
  }
}

export function fetchMe(): Promise<AuthUser> {
  return apiRequest<AuthUser>("/api/v1/me");
}
