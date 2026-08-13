"use client";

import { useState } from "react";
import { QueryClientProvider } from "@tanstack/react-query";

import { createQueryClient } from "@/lib/query-client";
import { AuthBootstrap } from "@/components/auth/auth-bootstrap";
import { InstallPrompt } from "@/components/pwa/install-prompt";
import { Toaster } from "@/components/ui/sonner";

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(createQueryClient);

  return (
    <QueryClientProvider client={queryClient}>
      <AuthBootstrap />
      {children}
      <InstallPrompt />
      <Toaster />
    </QueryClientProvider>
  );
}
