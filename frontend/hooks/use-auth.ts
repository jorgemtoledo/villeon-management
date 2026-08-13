"use client";

import { useCallback, useState } from "react";

import { login as loginRequest, logout as logoutRequest } from "@/lib/api/auth";
import { setSession } from "@/lib/auth/session-store";
import { useSession } from "@/lib/auth/use-session";
import { ApiError } from "@/lib/api/client";

export function useAuth() {
  const session = useSession();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const login = useCallback(async (email: string, password: string) => {
    setIsSubmitting(true);
    setError(null);
    try {
      const { token, user } = await loginRequest(email, password);
      setSession(token, user);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "Não foi possível conectar ao servidor.";
      setError(message);
      throw err;
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  const logout = useCallback(async () => {
    await logoutRequest();
  }, []);

  return {
    user: session.user,
    status: session.status,
    isSubmitting,
    error,
    login,
    logout,
  };
}
