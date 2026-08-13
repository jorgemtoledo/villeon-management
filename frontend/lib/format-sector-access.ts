import { SECTORS } from "@/lib/constants/sectors";

// Shared by users-table/users-cards — always names, never raw sector_ids.
export function formatSectorAccess(user: { all_sectors: boolean; sector_ids: number[] }): string {
  if (user.all_sectors) return "Todos os setores";
  if (user.sector_ids.length === 0) return "Nenhum setor";

  const names = user.sector_ids
    .map((id) => SECTORS.find((sector) => sector.id === id)?.name)
    .filter((name): name is string => !!name);

  return names.join(", ");
}
