"use client";

import { Search } from "lucide-react";

import { useStockAuditUsers } from "@/hooks/use-stock-audit-users";
import { STOCK_AUDIT_FIELD_LABEL } from "@/lib/format-stock-audit";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { StockAuditField } from "@/types/stock-audit";

export type FieldFilter = "all" | StockAuditField;

interface StockHistoryFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  userId: number | undefined;
  onUserChange: (userId: number | undefined) => void;
  field: FieldFilter;
  onFieldChange: (field: FieldFilter) => void;
  dateFrom: string;
  onDateFromChange: (value: string) => void;
  dateTo: string;
  onDateToChange: (value: string) => void;
}

const FIELD_ITEMS: Record<string, string> = { all: "Todos", ...STOCK_AUDIT_FIELD_LABEL };

export function StockHistoryFilters({
  search,
  onSearchChange,
  userId,
  onUserChange,
  field,
  onFieldChange,
  dateFrom,
  onDateFromChange,
  dateTo,
  onDateToChange,
}: StockHistoryFiltersProps) {
  const { data: usersData, isPending: usersPending } = useStockAuditUsers();
  const users = usersData?.data ?? [];

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-col gap-3 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search
            className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden="true"
          />
          <Input
            type="search"
            placeholder="Buscar por nome ou código do produto..."
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
            className="h-11 pl-9 md:h-9"
            aria-label="Buscar por produto"
          />
        </div>

        <Select
          value={userId ? String(userId) : "all"}
          onValueChange={(value) => onUserChange(value === "all" ? undefined : Number(value))}
          disabled={usersPending}
          items={{ all: "Todos os usuários", ...Object.fromEntries(users.map((u) => [ String(u.id), u.name ])) }}
        >
          <SelectTrigger className="h-11 w-full md:h-9 md:w-48" aria-label="Filtrar por usuário">
            <SelectValue placeholder="Todos os usuários" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos os usuários</SelectItem>
            {users.map((u) => (
              <SelectItem key={u.id} value={String(u.id)}>
                {u.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={field} onValueChange={(value) => onFieldChange(value as FieldFilter)} items={FIELD_ITEMS}>
          <SelectTrigger className="h-11 w-full md:h-9 md:w-48" aria-label="Filtrar por tipo de alteração">
            <SelectValue placeholder="Tipo de alteração" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos</SelectItem>
            {(Object.keys(STOCK_AUDIT_FIELD_LABEL) as StockAuditField[]).map((value) => (
              <SelectItem key={value} value={value}>
                {STOCK_AUDIT_FIELD_LABEL[value]}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center gap-2">
        <Label htmlFor="stock-history-date-from" className="sr-only">
          De
        </Label>
        <Input
          id="stock-history-date-from"
          type="date"
          value={dateFrom}
          onChange={(event) => onDateFromChange(event.target.value)}
          className="h-11 md:h-9"
          aria-label="Data inicial"
        />
        <span className="text-sm text-muted-foreground">até</span>
        <Label htmlFor="stock-history-date-to" className="sr-only">
          Até
        </Label>
        <Input
          id="stock-history-date-to"
          type="date"
          value={dateTo}
          onChange={(event) => onDateToChange(event.target.value)}
          className="h-11 md:h-9"
          aria-label="Data final"
        />
      </div>
    </div>
  );
}
