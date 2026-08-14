import type { LucideIcon } from "lucide-react";
import { History, Home, Package, ReceiptText, Truck, Users, Warehouse } from "lucide-react";

export interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
  // When true, SidebarNav only renders this item for admins — hiding it is
  // UX only, the real gate is the backend returning 403 either way.
  adminOnly?: boolean;
  // Same idea as adminOnly, but admin-or-manager (Bloco Histórico) — kept as
  // its own flag rather than generalizing adminOnly into a role list, since
  // there's only ever been these two shapes so far.
  managerOrAdminOnly?: boolean;
  // A group header with no page of its own — renders its children indented
  // underneath instead of being a clickable link. Only one level deep.
  children?: NavItem[];
}

// Home + Produtos + Fornecedores + Compras + Estoque (Estoque atual +
// Histórico de estoque) + Usuários. Home is the landing page after login
// (empty placeholder for now — becomes the real dashboard later); fichas
// técnicas is still out of scope. "Estoque atual" is NOT adminOnly — every
// role can need it (manager/operator do the actual counting), the page
// itself gates on sector access (StockNoSectorState) rather than hiding the
// nav item. "Histórico de estoque" (Bloco Histórico) is admin/manager only.
export const NAV_ITEMS: NavItem[] = [
  { href: "/home", label: "Home", icon: Home },
  { href: "/produtos", label: "Produtos", icon: Package },
  { href: "/fornecedores", label: "Fornecedores", icon: Truck },
  { href: "/compras", label: "Compras", icon: ReceiptText },
  {
    href: "/estoque",
    label: "Estoque",
    icon: Warehouse,
    children: [
      { href: "/estoque", label: "Estoque atual", icon: Warehouse },
      { href: "/estoque/historico", label: "Histórico de estoque", icon: History, managerOrAdminOnly: true },
    ],
  },
  { href: "/usuarios", label: "Usuários", icon: Users, adminOnly: true },
];
