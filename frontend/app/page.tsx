"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

import { useSession } from "@/lib/auth/use-session";

export default function RootPage() {
  const { status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === "authenticated") {
      router.replace("/produtos");
    } else if (status === "unauthenticated") {
      router.replace("/login");
    }
  }, [status, router]);

  return (
    <div className="flex min-h-svh items-center justify-center bg-villeon-green-900">
      <div className="size-8 animate-spin rounded-full border-2 border-villeon-cream/30 border-t-villeon-cream" />
    </div>
  );
}
