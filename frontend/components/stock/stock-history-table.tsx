import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatDateTime } from "@/lib/format-date";
import { STOCK_AUDIT_FIELD_LABEL, formatStockAuditValue } from "@/lib/format-stock-audit";
import type { StockAuditEntry } from "@/types/stock-audit";

interface StockHistoryTableProps {
  entries: StockAuditEntry[];
  // false in the per-product drawer (StockHistorySheet) — every row is
  // already the same product there, repeating it in every row is noise.
  showProduct?: boolean;
}

// Desktop/tablet only (≥md / 768px) — see StockHistoryCards for the mobile
// equivalent. Always already sorted by the API (created_at desc), never
// re-sorted client-side.
export function StockHistoryTable({ entries, showProduct = true }: StockHistoryTableProps) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Data/Hora</TableHead>
            {showProduct ? (
              <>
                <TableHead>Produto</TableHead>
                <TableHead>Código</TableHead>
              </>
            ) : null}
            <TableHead>Usuário</TableHead>
            <TableHead>Alteração</TableHead>
            <TableHead>Antes</TableHead>
            <TableHead>Depois</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {entries.map((entry) => (
            <TableRow key={entry.id}>
              <TableCell className="text-muted-foreground">{formatDateTime(entry.created_at)}</TableCell>
              {showProduct ? (
                <>
                  <TableCell className="font-medium">{entry.product.name}</TableCell>
                  <TableCell className="text-muted-foreground">{entry.product.code}</TableCell>
                </>
              ) : null}
              <TableCell>{entry.user.name}</TableCell>
              <TableCell>{STOCK_AUDIT_FIELD_LABEL[entry.field]}</TableCell>
              <TableCell>{formatStockAuditValue(entry.field, entry.previous_value)}</TableCell>
              <TableCell>{formatStockAuditValue(entry.field, entry.new_value)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
