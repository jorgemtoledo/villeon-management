"use client";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import type { StockStatus } from "@/types/product-stock";

const ALL_VALUE = "all";
const STATUS_OPTIONS = Object.keys(STOCK_STATUS_LABEL) as StockStatus[];

interface StockStatusSelectProps {
  value: StockStatus | undefined;
  onChange: (status: StockStatus | undefined) => void;
}

export function StockStatusSelect({ value, onChange }: StockStatusSelectProps) {
  return (
    <Select
      value={value ?? ALL_VALUE}
      onValueChange={(next) => onChange(next === ALL_VALUE ? undefined : (next as StockStatus))}
      items={{ [ALL_VALUE]: "Todos os status", ...STOCK_STATUS_LABEL }}
    >
      <SelectTrigger className="h-11 w-full md:h-9 md:w-48" aria-label="Filtrar por status">
        <SelectValue placeholder="Todos os status" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value={ALL_VALUE}>Todos os status</SelectItem>
        {STATUS_OPTIONS.map((status) => (
          <SelectItem key={status} value={status}>
            {STOCK_STATUS_LABEL[status]}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
