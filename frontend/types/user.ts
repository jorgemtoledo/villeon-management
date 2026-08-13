// Mirrors UserSerializer#call exactly — keep in sync with the Rails serializer.
// Never has an encrypted_password/password/jti/reset_password_token field —
// the backend never sends those, on purpose.
import type { PaginationMeta } from "@/types/pagination";
import type { UserRole } from "@/types/auth";

export type { UserRole };

export interface User {
  id: number;
  name: string;
  email: string;
  role: UserRole;
  active: boolean;
  all_sectors: boolean;
  sector_ids: number[];
  created_at: string;
  updated_at: string;
}

export interface UsersResponse {
  data: User[];
  meta: PaginationMeta;
}

export interface UsersQuery {
  q?: string;
  role?: UserRole;
  active?: boolean;
  page?: number;
  perPage?: number;
  sort?: "name" | "email" | "created_at";
  order?: "asc" | "desc";
}

// Mirrors Api::V1::UsersController#user_params — password/password_confirmation
// are optional (omit both on an edit that isn't changing the password; the
// backend leaves the existing password untouched when they're absent/blank).
export interface UserInput {
  name: string;
  email: string;
  role: UserRole;
  all_sectors: boolean;
  sector_ids: number[];
  password?: string;
  password_confirmation?: string;
}
