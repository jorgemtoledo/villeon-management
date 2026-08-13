"use client";

import { useState } from "react";
import Image from "next/image";
import { Menu } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { SidebarNav } from "@/components/layout/sidebar-nav";

// Mobile + tablet only (<lg / 1024px) — the desktop Sidebar is hidden here
// and replaced by this Sheet-based drawer, per the responsive requirement
// that the nav never permanently occupies screen space on a phone.
export function MobileDrawer() {
  const [open, setOpen] = useState(false);

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Abrir menu" />
        }
      >
        <Menu className="size-5" aria-hidden="true" />
      </SheetTrigger>
      <SheetContent
        side="left"
        className="w-3/4 max-w-xs bg-sidebar p-0 text-sidebar-foreground"
      >
        <SheetHeader className="flex-row items-center gap-2 border-b border-sidebar-border">
          <Image
            src="/brand/villeon-icon.png"
            alt=""
            width={28}
            height={28}
            className="size-7 rounded-md"
          />
          <SheetTitle className="text-sidebar-foreground">VILLEON</SheetTitle>
        </SheetHeader>
        <div className="py-2">
          <SidebarNav onNavigate={() => setOpen(false)} />
        </div>
      </SheetContent>
    </Sheet>
  );
}
