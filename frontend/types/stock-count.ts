// Mirrors StockCountSerializer#call exactly.
export interface StockCount {
  id: number;
  product: { id: number; name: string; code: string };
  user: { id: number; name: string };
  quantity: string;
  counted_at: string;
  created_at: string;
  updated_at: string;
}

// Mirrors Api::V1::StockCountsController#stock_count_params. counted_at is
// omitted here — the backend defaults it to Time.current when absent, and
// the operational screen never needs to backdate a count.
export interface StockCountInput {
  quantity: number;
}
