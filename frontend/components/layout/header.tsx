import Image from "next/image";

import { MobileDrawer } from "@/components/layout/mobile-drawer";
import { UserMenu } from "@/components/layout/user-menu";

export function Header() {
  return (
    <header className="flex h-16 shrink-0 items-center justify-between gap-3 border-b border-border bg-background px-4 sm:px-6">
      <div className="flex items-center gap-3">
        <MobileDrawer />
        <div className="flex items-center gap-2 lg:hidden">
          <Image
            src="/brand/villeon-icon.png"
            alt="VILLEON"
            width={28}
            height={28}
            className="size-7 rounded-md"
          />
          <span className="font-semibold text-foreground">VILLEON</span>
        </div>
      </div>
      <UserMenu />
    </header>
  );
}
