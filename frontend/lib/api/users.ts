import { apiRequest } from "@/lib/api/client";
import type { User, UserInput, UsersQuery, UsersResponse } from "@/types/user";

function buildQueryString(query: UsersQuery): string {
  const params = new URLSearchParams();

  if (query.q) params.set("q", query.q);
  if (query.role) params.set("role", query.role);
  if (query.active !== undefined) params.set("active", String(query.active));
  if (query.page) params.set("page", String(query.page));
  if (query.perPage) params.set("per_page", String(query.perPage));
  if (query.sort) params.set("sort", query.sort);
  if (query.order) params.set("order", query.order);

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function fetchUsers(query: UsersQuery): Promise<UsersResponse> {
  return apiRequest<UsersResponse>(`/api/v1/users${buildQueryString(query)}`);
}

export function fetchUser(id: number | string): Promise<User> {
  return apiRequest<User>(`/api/v1/users/${id}`);
}

export function createUser(input: UserInput): Promise<User> {
  return apiRequest<User>("/api/v1/users", {
    method: "POST",
    body: JSON.stringify({ user: input }),
  });
}

export function updateUser(id: number, input: UserInput): Promise<User> {
  return apiRequest<User>(`/api/v1/users/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ user: input }),
  });
}

export function activateUser(id: number): Promise<User> {
  return apiRequest<User>(`/api/v1/users/${id}/activate`, { method: "PATCH" });
}

export function deactivateUser(id: number): Promise<User> {
  return apiRequest<User>(`/api/v1/users/${id}/deactivate`, { method: "PATCH" });
}
