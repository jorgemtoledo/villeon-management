// purchased_at arrives as an ISO datetime string (UTC midnight — Purchase
// only ever stores a date, no meaningful time-of-day). Formatted with UTC
// explicitly so a purchase dated 2026-01-02 never shifts to 2026-01-01 in a
// browser west of UTC.
export function formatDate(value: string): string {
  return new Date(value).toLocaleDateString("pt-BR", { timeZone: "UTC" });
}

// For real timestamps (e.g. StockAuditEntry#created_at) — unlike formatDate
// above, this is NOT pinned to UTC: the value carries a meaningful time of
// day, so it's shown in the viewer's own local time, same as any other
// "when did this happen" timestamp.
export function formatDateTime(value: string): string {
  return new Date(value).toLocaleString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
