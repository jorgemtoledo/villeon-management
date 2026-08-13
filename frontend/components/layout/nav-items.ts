import type { LucideIcon } from "lucide-react";
import { Package, ReceiptText, Truck, Users, Warehouse } from "lucide-react";

export interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
  // When true, SidebarNav only renders this item for admins — hiding it is
  // UX only, the real gate is the backend returning 403 either way.
  adminOnly?: boolean;
}

// Produtos + Fornecedores + Compras + Estoque + Usuários. Dashboard/fichas
// técnicas are still out of scope. Estoque is NOT adminOnly — every role can
// need it (manager/operator do the actual counting), the page itself gates
// on sector access (StockNoSectorState) rather than hiding the nav item.
export const NAV_ITEMS: NavItem[] = [
  { href: "/produtos", label: "Produtos", icon: Package },
  { href: "/fornecedores", label: "Fornecedores", icon: Truck },
  { href: "/compras", label: "Compras", icon: ReceiptText },
  { href: "/estoque", label: "Estoque", icon: Warehouse },
  { href: "/usuarios", label: "Usuários", icon: Users, adminOnly: true },
];
