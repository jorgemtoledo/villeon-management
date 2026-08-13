"use client";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { SectorOption } from "@/lib/constants/sectors";

interface StockSectorSelectProps {
  // Already filtered to what this user is allowed to operate — never the
  // full SECTORS list unconditionally (see lib/auth/permissions#allowedSectors).
  sectors: SectorOption[];
  value: number | undefined;
  onChange: (sectorId: number) => void;
}

export function StockSectorSelect({ sectors, value, onChange }: StockSectorSelectProps) {
  return (
    <Select
      value={value !== undefined ? String(value) : ""}
      onValueChange={(next) => onChange(Number(next))}
      items={Object.fromEntries(sectors.map((sector) => [ String(sector.id), sector.name ]))}
    >
      <SelectTrigger className="h-11 w-full md:h-9 md:w-56" aria-label="Selecionar setor">
        <SelectValue placeholder="Selecione o setor" />
      </SelectTrigger>
      <SelectContent>
        {sectors.map((sector) => (
          <SelectItem key={sector.id} value={String(sector.id)}>
            {sector.name}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
