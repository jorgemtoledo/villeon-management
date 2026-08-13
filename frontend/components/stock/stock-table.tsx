import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatStockQuantity } from "@/lib/format-quantity";
import { STOCK_STATUS_BADGE_VARIANT, STOCK_STATUS_LABEL } from "@/lib/format-stock-status";
import type { ProductStock } from "@/types/product-stock";

interface StockTableProps {
  rows: ProductStock[];
  onCount: (row: ProductStock) => void;
}

// Desktop/tablet only (≥md / 768px) — see StockCards for the mobile
// equivalent. Every number here comes straight from StockCalculator via the
// API — nothing is recomputed client-side.
export function StockTable({ rows, onCount }: StockTableProps) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Produto</TableHead>
            <TableHead>Código</TableHead>
            <TableHead>Unidade</TableHead>
            <TableHead className="text-right">Estoque atual</TableHead>
            <TableHead className="text-right">Mínimo</TableHead>
            <TableHead className="text-right">Ideal</TableHead>
            <TableHead className="text-right">Reposição</TableHead>
            <TableHead className="text-right">Comprar</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Contagem</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={row.product.id}>
              <TableCell className="font-medium">{row.product.name}</TableCell>
              <TableCell className="text-muted-foreground">{row.product.code}</TableCell>
              <TableCell>{row.stock_unit?.abbreviation ?? "—"}</TableCell>
              <TableCell className="text-right">{formatStockQuantity(row.current_quantity)}</TableCell>
              <TableCell className="text-right">{formatStockQuantity(row.minimum_quantity)}</TableCell>
              <TableCell className="text-right">{formatStockQuantity(row.ideal_quantity)}</TableCell>
              <TableCell className="text-right">{formatStockQuantity(row.replenishment_quantity)}</TableCell>
              <TableCell className="text-right">{row.purchase_quantity ?? "—"}</TableCell>
              <TableCell>
                <Badge variant={STOCK_STATUS_BADGE_VARIANT[row.status]}>{STOCK_STATUS_LABEL[row.status]}</Badge>
              </TableCell>
              <TableCell>
                <Button type="button" variant="outline" size="sm" className="h-11 md:h-9" onClick={() => onCount(row)}>
                  {row.status === "nao_contado" ? "Contar" : "Atualizar"}
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
