// purchased_at arrives as an ISO datetime string (UTC midnight — Purchase
// only ever stores a date, no meaningful time-of-day). Formatted with UTC
// explicitly so a purchase dated 2026-01-02 never shifts to 2026-01-01 in a
// browser west of UTC.
export function formatDate(value: string): string {
  return new Date(value).toLocaleDateString("pt-BR", { timeZone: "UTC" });
}
