// Mirrors UnitSerializer#call exactly — keep in sync with the Rails serializer.
export interface Unit {
  id: number;
  name: string;
  abbreviation: string;
}

// GET /api/v1/units is deliberately unpaginated (33 rows) — no `meta`.
export interface UnitsResponse {
  data: Unit[];
}
