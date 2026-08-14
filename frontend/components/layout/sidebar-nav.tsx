"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { NAV_ITEMS, type NavItem } from "@/components/layout/nav-items";
import { useAuth } from "@/hooks/use-auth";
import { isAdmin, canViewStockHistory } from "@/lib/auth/permissions";
import { cn } from "@/lib/utils";
import type { AuthUser } from "@/types/auth";

function isVisible(item: NavItem, user: AuthUser | null | undefined): boolean {
  if (item.adminOnly && !isAdmin(user)) return false;
  if (item.managerOrAdminOnly && !canViewStockHistory(user)) return false;
  return true;
}

interface NavLinkProps {
  item: NavItem;
  active: boolean;
  indented?: boolean;
  onNavigate?: () => void;
}

function NavLink({ item, active, indented, onNavigate }: NavLinkProps) {
  const Icon = item.icon;

  return (
    <Link
      href={item.href}
      onClick={onNavigate}
      className={cn(
        "flex min-h-11 items-center gap-3 rounded-md px-3 text-sm font-medium transition-colors",
        indented && "ml-3",
        active
          ? "bg-sidebar-primary text-sidebar-primary-foreground"
          : "text-sidebar-foreground/80 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
      )}
    >
      <Icon className="size-4 shrink-0" aria-hidden="true" />
      {item.label}
    </Link>
  );
}

export function SidebarNav({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  const { user } = useAuth();
  const items = NAV_ITEMS.filter((item) => isVisible(item, user));

  return (
    <nav className="flex flex-col gap-1 px-3">
      {items.map((item) => {
        if (item.children) {
          const children = item.children.filter((child) => isVisible(child, user));

          return (
            <div key={item.href} className="flex flex-col gap-1">
              <div className="flex min-h-11 items-center gap-3 px-3 text-sm font-medium text-sidebar-foreground/60">
                <item.icon className="size-4 shrink-0" aria-hidden="true" />
                {item.label}
              </div>
              {children.map((child) => (
                <NavLink key={child.href} item={child} active={pathname === child.href} indented onNavigate={onNavigate} />
              ))}
            </div>
          );
        }

        return (
          <NavLink
            key={item.href}
            item={item}
            active={pathname.startsWith(item.href)}
            onNavigate={onNavigate}
          />
        );
      })}
    </nav>
  );
}
