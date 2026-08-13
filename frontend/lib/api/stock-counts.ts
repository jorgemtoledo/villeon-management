import { apiRequest } from "@/lib/api/client";
import type { StockCount, StockCountInput } from "@/types/stock-count";

export function createStockCount(productId: number, input: StockCountInput): Promise<StockCount> {
  return apiRequest<StockCount>(`/api/v1/products/${productId}/stock_counts`, {
    method: "POST",
    body: JSON.stringify({ stock_count: input }),
  });
}
