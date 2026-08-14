import Image from "next/image";

import { MobileDrawer } from "@/components/layout/mobile-drawer";
import { UserMenu } from "@/components/layout/user-menu";

// Below lg, this bar doubles as the mobile "brand bar" (Sidebar itself is
// hidden — see AppShell), so it's styled like the sidebar (dark green,
// villeon-cream text) instead of the plain light bg used at lg+, where the
// brand already lives in the real Sidebar and this becomes a normal content
// header (just the user menu). Sticky below lg only — on a phone, AppShell's
// `main` scrolls the whole page (no internal scroll container), so without
// this the header/menu trigger/user menu scroll away with the content. At
// lg+ the Sidebar already stays put on its own, so the header doesn't need
// to (`lg:static`).
export function Header() {
  return (
    <header className="sticky top-0 z-40 flex h-16 shrink-0 items-center justify-between gap-3 border-b border-sidebar-border bg-sidebar px-4 text-sidebar-foreground sm:px-6 lg:static lg:border-border lg:bg-background lg:text-foreground">
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
          <span className="font-semibold text-sidebar-foreground">VILLEON</span>
        </div>
      </div>
      <UserMenu />
    </header>
  );
}
