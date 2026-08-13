import { ChevronLeft, ChevronRight } from "lucide-react";

import { Button } from "@/components/ui/button";
import type { PaginationMeta } from "@/types/pagination";

interface PaginationProps {
  meta: PaginationMeta;
  onPageChange: (page: number) => void;
  // e.g. "produtos", "fornecedores" — keeps the summary line's wording
  // correct per resource without duplicating this whole component.
  itemLabel: string;
}

export function Pagination({ meta, onPageChange, itemLabel }: PaginationProps) {
  if (meta.total_pages <= 1) return null;

  const canGoBack = meta.page > 1;
  const canGoForward = meta.page < meta.total_pages;

  return (
    <div className="flex items-center justify-between gap-3 pt-2">
      <p className="text-sm text-muted-foreground">
        Página {meta.page} de {meta.total_pages} · {meta.total_count} {itemLabel}
      </p>
      <div className="flex gap-2">
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="size-11 md:size-9"
          disabled={!canGoBack}
          onClick={() => onPageChange(meta.page - 1)}
          aria-label="Página anterior"
        >
          <ChevronLeft className="size-4" />
        </Button>
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="size-11 md:size-9"
          disabled={!canGoForward}
          onClick={() => onPageChange(meta.page + 1)}
          aria-label="Próxima página"
        >
          <ChevronRight className="size-4" />
        </Button>
      </div>
    </div>
  );
}
