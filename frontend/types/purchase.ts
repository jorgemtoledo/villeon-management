// Mirrors PurchaseSerializer/PurchaseDetailSerializer#call exactly — keep in
// sync with the Rails serializers. Decimal columns (total_amount, quantity,
// unit_price, total_price) serialize as STRING (confirmed against the real
// API, e.g. `"total_amount":"214.0"`), not number — format with
// formatCurrency/Number() at render time, never assume a numeric type here.
import type { PaginationMeta } from "@/types/pagination";
import type { NamedReference, UnitReference } from "@/types/product";

export interface Purchase {
  id: number;
  purchased_at: string;
  supplier: NamedReference;
  total_amount: string;
  items_count: number;
}

export interface PurchaseItem {
  id: number;
  product: { id: number; name: string; code: string };
  quantity: string;
  unit: UnitReference | null;
  unit_price: string;
  total_price: string;
}

export interface PurchaseDetail {
  id: number;
  purchased_at: string;
  supplier: NamedReference;
  total_amount: string;
  invoice_number: string | null;
  items: PurchaseItem[];
}

export interface PurchasesResponse {
  data: Purchase[];
  meta: PaginationMeta;
}

export interface PurchasesQuery {
  q?: string;
  supplierId?: number;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  perPage?: number;
  sort?: "purchased_at" | "total_amount" | "created_at";
  order?: "asc" | "desc";
}

// Mirrors Api::V1::PurchasesController#purchase_params exactly. total_amount
// is deliberately absent — the backend always computes it from the items
// and never trusts a client-sent value (Bloco 6H.1).
export interface PurchaseInput {
  supplier_id: number;
  purchased_at: string;
  invoice_number?: string | null;
  items: Array<{
    product_id: number;
    quantity: number;
    unit_price: number;
  }>;
}
