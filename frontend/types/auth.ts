export type UserRole = "admin" | "manager" | "operator";

// Mirrors Api::V1::SessionsController#user_payload / Api::V1::MeController#user_payload.
// `sector_id` (singular) never appeared in either payload's contract before
// this — only Product had its own, unrelated `sector_id` (see types/product.ts).
export interface AuthUser {
  id: number;
  email: string;
  name: string;
  role: UserRole;
  active?: boolean;
  all_sectors: boolean;
  sector_ids: number[];
}
