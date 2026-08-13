import type { LucideIcon } from "lucide-react";
import { Home, Package, ReceiptText, Truck, Users, Warehouse } from "lucide-react";

export interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
  // When true, SidebarNav only renders this item for admins — hiding it is
  // UX only, the real gate is the backend returning 403 either way.
  adminOnly?: boolean;
}

// Home + Produtos + Fornecedores + Compras + Estoque + Usuários. Home is the
// landing page after login (empty placeholder for now — becomes the real
// dashboard later); fichas técnicas is still out of scope. Estoque is NOT
// adminOnly — every role can need it (manager/operator do the actual
// counting), the page itself gates on sector access (StockNoSectorState)
// rather than hiding the nav item.
export const NAV_ITEMS: NavItem[] = [
  { href: "/home", label: "Home", icon: Home },
  { href: "/produtos", label: "Produtos", icon: Package },
  { href: "/fornecedores", label: "Fornecedores", icon: Truck },
  { href: "/compras", label: "Compras", icon: ReceiptText },
  { href: "/estoque", label: "Estoque", icon: Warehouse },
  { href: "/usuarios", label: "Usuários", icon: Users, adminOnly: true },
];
