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

export type StatusFilter = "all" | "active" | "inactive";

interface SuppliersFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  status: StatusFilter;
  onStatusChange: (status: StatusFilter) => void;
}

const STATUS_LABELS: Record<StatusFilter, string> = {
  all: "Todos",
  active: "Ativos",
  inactive: "Inativos",
};

// No sector-equivalent filter exists for suppliers (the API only accepts
// `q`/`active`), so besides search this is just the status Select — same
// pattern as ProductsFilters' status filter (Bloco 6B).
export function SuppliersFilters({ search, onSearchChange, status, onStatusChange }: SuppliersFiltersProps) {
  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-center">
      <div className="relative flex-1">
        <Search
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden="true"
        />
        <Input
          type="search"
          placeholder="Buscar por nome ou CNPJ..."
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          className="h-11 pl-9 md:h-9"
          aria-label="Buscar fornecedores"
        />
      </div>

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
