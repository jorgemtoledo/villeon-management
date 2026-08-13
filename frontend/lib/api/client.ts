import { API_URL } from "@/lib/env";
import { clearSession, getToken } from "@/lib/auth/session-store";

export class ApiError extends Error {
  status: number;
  details?: string[];

  constructor(status: number, message: string, details?: string[]) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.details = details;
  }
}

interface ApiRequestOptions extends RequestInit {
  // Set false for endpoints that must be reachable without a token (login).
  auth?: boolean;
}

export async function apiRequest<T>(path: string, options: ApiRequestOptions = {}): Promise<T> {
  const { auth = true, headers, ...rest } = options;

  const finalHeaders = new Headers(headers);
  finalHeaders.set("Accept", "application/json");
  if (rest.body && !(rest.body instanceof FormData)) {
    finalHeaders.set("Content-Type", "application/json");
  }
  if (auth) {
    const token = getToken();
    if (token) finalHeaders.set("Authorization", `Bearer ${token}`);
  }

  const response = await fetch(`${API_URL}${path}`, { ...rest, headers: finalHeaders });

  // Token expired/revoked (e.g. logged out from another device): drop the
  // local session so RequireAuth reacts and redirects to /login.
  if (response.status === 401 && auth) {
    clearSession();
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const isJson = response.headers.get("content-type")?.includes("application/json") ?? false;
  const body = isJson ? await response.json() : null;

  if (!response.ok) {
    const message = body?.error ?? "Erro inesperado ao comunicar com o servidor.";
    throw new ApiError(response.status, message, body?.details);
  }

  return body as T;
}
