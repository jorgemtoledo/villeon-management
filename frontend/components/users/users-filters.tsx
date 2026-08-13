"use client";

import { Search } from "lucide-react";

import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { UserRole } from "@/types/user";

export type StatusFilter = "all" | "active" | "inactive";
export type RoleFilter = "all" | UserRole;

interface UsersFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  role: RoleFilter;
  onRoleChange: (role: RoleFilter) => void;
  status: StatusFilter;
  onStatusChange: (status: StatusFilter) => void;
}

const ROLE_LABELS: Record<RoleFilter, string> = {
  all: "Todos os papéis",
  admin: "Administrador",
  manager: "Gerente",
  operator: "Operador",
};

const STATUS_LABELS: Record<StatusFilter, string> = {
  all: "Todos",
  active: "Ativos",
  inactive: "Inativos",
};

export function UsersFilters({ search, onSearchChange, role, onRoleChange, status, onStatusChange }: UsersFiltersProps) {
  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-center">
      <div className="relative flex-1">
        <Search
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden="true"
        />
        <Input
          type="search"
          placeholder="Buscar por nome ou e-mail..."
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          className="h-11 pl-9 md:h-9"
          aria-label="Buscar usuários"
        />
      </div>

      <Select value={role} onValueChange={(value) => onRoleChange(value as RoleFilter)} items={ROLE_LABELS}>
        <SelectTrigger className="h-11 w-full md:h-9 md:w-48" aria-label="Filtrar por papel">
          <SelectValue placeholder="Todos os papéis" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Todos os papéis</SelectItem>
          <SelectItem value="admin">Administrador</SelectItem>
          <SelectItem value="manager">Gerente</SelectItem>
          <SelectItem value="operator">Operador</SelectItem>
        </SelectContent>
      </Select>

      <Select value={status} onValueChange={(value) => onStatusChange(value as StatusFilter)} items={STATUS_LABELS}>
        <SelectTrigger className="h-11 w-full md:h-9 md:w-36" aria-label="Filtrar por status">
          <SelectValue placeholder="Status" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Todos</SelectItem>
          <SelectItem value="active">Ativos</SelectItem>
          <SelectItem value="inactive">Inativos</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}
