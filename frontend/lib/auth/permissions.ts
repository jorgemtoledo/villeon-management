import { SECTORS, type SectorOption } from "@/lib/constants/sectors";
import type { AuthUser } from "@/types/auth";

// Centralizes what used to be `user?.role === "admin"` copy-pasted per page.
// UX-only — the backend/Ability is the real authorization, these functions
// exist so components stop duplicating (and risking drifting on) the same
// check, not to move security into the frontend.

export function isAdmin(user: AuthUser | null | undefined): boolean {
  return user?.role === "admin";
}

// Product/Supplier CRUD is admin-only today (same rule as isAdmin) — kept as
// its own named function because the rule is conceptually about the
// resource, not about being admin, even though they coincide right now.
export function canManageProducts(user: AuthUser | null | undefined): boolean {
  return isAdmin(user);
}

export function canManageSuppliers(user: AuthUser | null | undefined): boolean {
  return isAdmin(user);
}

// User management is admin-only (Bloco 6F) — same rule as isAdmin, kept as
// its own named function for the same reason as the two above.
export function canManageUsers(user: AuthUser | null | undefined): boolean {
  return isAdmin(user);
}

// Purchase create/edit (Bloco 6H.2/6H.3): mirrors Ability exactly — admin
// (manage :all) plus manager (`can %i[create update], Purchase if
// user.manager?`). Operator is excluded. Not sector-scoped, unlike Estoque.
// Same rule for both actions, so one function covers both — matches
// canManageProducts above (also one function for create/update/activate/...).
export function canManagePurchases(user: AuthUser | null | undefined): boolean {
  return isAdmin(user) || user?.role === "manager";
}

// Sector access helpers, consumed by /estoque (Bloco 6G Parte 3) — mirrors
// User#has_all_sector_access?/#sector_ids exactly. UX-only, same as above:
// the real gate is the backend's Ability (product: { sector_id: ... }).
export function hasAllSectorAccess(user: AuthUser | null | undefined): boolean {
  return isAdmin(user) || user?.all_sectors === true;
}

export function hasSectorAccess(user: AuthUser | null | undefined, sectorId: number): boolean {
  if (hasAllSectorAccess(user)) return true;
  return user?.sector_ids.includes(sectorId) ?? false;
}

// The sectors this user can operate stock in — every Sector when
// hasAllSectorAccess, otherwise only their assigned ones. Drives which
// options /estoque's sector selector offers; an empty result means the user
// has no stock access at all (StockNoSectorState).
export function allowedSectors(user: AuthUser | null | undefined): SectorOption[] {
  return SECTORS.filter((sector) => hasSectorAccess(user, sector.id));
}

// Priority/needs_advance_order (Bloco 6G Parte 4) — mirrors Ability's
// update_priority rule + ProductStocksController#locked_for_current_user?
// exactly: admin/manager always, any sector; a sector-authorized operator
// only the *first* time (never once alreadyConfigured is true). UX-only,
// same caveat as the rest of this file — the backend re-checks all of this
// independently and is the only real authority.
export function canEditStockPriority(
  user: AuthUser | null | undefined,
  sectorId: number | null | undefined,
  alreadyConfigured: boolean,
): boolean {
  if (isAdmin(user) || user?.role === "manager") return true;
  if (alreadyConfigured) return false;
  return sectorId != null && hasSectorAccess(user, sectorId);
}
