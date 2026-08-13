"use client";

import { Search } from "lucide-react";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface PurchasesFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  dateFrom: string;
  onDateFromChange: (value: string) => void;
  dateTo: string;
  onDateToChange: (value: string) => void;
}

// No supplier Select here on purpose: with 101 suppliers and no searchable
// combobox component in the app yet, a plain dropdown would be unusable and
// a real one is a bigger, separate piece of work. `q` already searches by
// supplier name (approved), which covers the same need for this block —
// `supplier_id` stays fully supported by the API for a future direct link
// (e.g. from a supplier's detail page).
export function PurchasesFilters({
  search,
  onSearchChange,
  dateFrom,
  onDateFromChange,
  dateTo,
  onDateToChange,
}: PurchasesFiltersProps) {
  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-center">
      <div className="relative flex-1">
        <Search
          className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden="true"
        />
        <Input
          type="search"
          placeholder="Buscar por fornecedor ou nota..."
          value={search}
          onChange={(event) => onSearchChange(event.target.value)}
          className="h-11 pl-9 md:h-9"
          aria-label="Buscar compras"
        />
      </div>

      <div className="flex items-center gap-2">
        <Label htmlFor="purchases-date-from" className="sr-only">
          De
        </Label>
        <Input
          id="purchases-date-from"
          type="date"
          value={dateFrom}
          onChange={(event) => onDateFromChange(event.target.value)}
          className="h-11 md:h-9"
          aria-label="Data inicial"
        />
        <span className="text-sm text-muted-foreground">até</span>
        <Label htmlFor="purchases-date-to" className="sr-only">
          Até
        </Label>
        <Input
          id="purchases-date-to"
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
