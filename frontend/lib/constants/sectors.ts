// Static reference list for the sector filter — there is no /sectors
// endpoint (out of scope for this block) and the domain only has these 5
// fixed sectors, seeded once in Bloco 3A (db/seeds.rb) and never changed by
// end users. IDs confirmed against the dev database on 2026-08-10:
//   1 Cozinha, 2 Confeitaria, 3 Bar, 4 Vinhos, 5 Limpeza
// If Sector rows are ever reseeded on a fresh database in a different order,
// or a 6th sector is added, update this list to match.
export interface SectorOption {
  id: number;
  name: string;
}

export const SECTORS: SectorOption[] = [
  { id: 1, name: "Cozinha" },
  { id: 2, name: "Confeitaria" },
  { id: 3, name: "Bar" },
  { id: 4, name: "Vinhos" },
  { id: 5, name: "Limpeza" },
];
