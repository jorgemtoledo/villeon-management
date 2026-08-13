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
import { SECTORS } from "@/lib/constants/sectors";

export type StatusFilter = "all" | "active" | "inactive";

interface ProductsFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  sectorId: number | undefined;
  onSectorChange: (sectorId: number | undefined) => void;
  status: StatusFilter;
  onStatusChange: (status: StatusFilter) => void;
}

const STATUS_LABELS: Record<StatusFilter, string> = {
  all: "Todos",
  active: "Ativos",
  inactive: "Inativos",
};

export function ProductsFilters({
  search,
  onSearchChange,
  sectorId,
  onSectorChange,
  status,
  onStatusChange,
}: ProductsFiltersProps) {
  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-center">
      <div className="relative flex-1">
        <Search
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden="true"
        />
        <Input
          type="search"
          placeholder="Buscar por nome ou código..."
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          className="h-11 pl-9 md:h-9"
          aria-label="Buscar produtos"
        />
      </div>

      <Select
        value={sectorId ? String(sectorId) : "all"}
        onValueChange={(value) => onSectorChange(value === "all" ? undefined : Number(value))}
        // Base UI's SelectValue resolves the trigger's displayed label from
        // this map, not from the mounted SelectItem children — without it,
        // the trigger shows the raw value ("3") instead of "Bar".
        items={{
          all: "Todos os setores",
          ...Object.fromEntries(SECTORS.map((sector) => [String(sector.id), sector.name])),
        }}
      >
        <SelectTrigger className="h-11 w-full md:h-9 md:w-48" aria-label="Filtrar por setor">
          <SelectValue placeholder="Todos os setores" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Todos os setores</SelectItem>
          {SECTORS.map((sector) => (
            <SelectItem key={sector.id} value={String(sector.id)}>
              {sector.name}
            </SelectItem>
          ))}
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
