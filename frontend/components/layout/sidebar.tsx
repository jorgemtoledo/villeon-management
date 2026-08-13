import Image from "next/image";

import { SidebarNav } from "@/components/layout/sidebar-nav";

// Desktop only (≥lg / 1024px) — fixed, always visible. Below lg, navigation
// moves into the MobileDrawer instead (see AppShell).
export function Sidebar() {
  return (
    <aside className="hidden w-64 shrink-0 flex-col border-r border-sidebar-border bg-sidebar lg:flex">
      <div className="flex h-16 items-center gap-2 px-4">
        <Image
          src="/brand/villeon-icon.png"
          alt=""
          width={32}
          height={32}
          className="size-8 rounded-md"
        />
        <span className="font-semibold tracking-wide text-sidebar-foreground">
          VILLEON
        </span>
      </div>
      <div className="flex-1 overflow-y-auto py-2">
        <SidebarNav />
      </div>
    </aside>
  );
}
