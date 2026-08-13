"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

import { useSession } from "@/lib/auth/use-session";

// Client-side route guard. Not a Next.js middleware.ts: the JWT lives in
// localStorage (per the Bearer-header requirement), which Next's edge
// middleware cannot read (it only sees cookies) — so protection has to
// happen after the client mounts, not at the edge.
export function RequireAuth({ children }: { children: React.ReactNode }) {
  const { status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === "unauthenticated") {
      router.replace("/login");
    }
  }, [status, router]);

  if (status === "authenticated") {
    return <>{children}</>;
  }

  return (
    <div className="flex min-h-svh items-center justify-center bg-villeon-green-900">
      <div className="size-8 animate-spin rounded-full border-2 border-villeon-cream/30 border-t-villeon-cream" />
    </div>
  );
}
