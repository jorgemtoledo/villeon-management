import { apiRequest } from "@/lib/api/client";
import type {
  ProductStock,
  ProductStockConfigInput,
  ProductStockPriorityInput,
  ProductStocksQuery,
  ProductStocksResponse,
} from "@/types/product-stock";

function buildQueryString(query: ProductStocksQuery): string {
  const params = new URLSearchParams();

  if (query.sectorId) params.set("sector_id", String(query.sectorId));
  if (query.status) params.set("status", query.status);
  if (query.active !== undefined) params.set("active", String(query.active));
  if (query.page) params.set("page", String(query.page));
  if (query.perPage) params.set("per_page", String(query.perPage));

  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function fetchProductStocks(query: ProductStocksQuery): Promise<ProductStocksResponse> {
  return apiRequest<ProductStocksResponse>(`/api/v1/product_stocks${buildQueryString(query)}`);
}

export function fetchProductStock(productId: number): Promise<ProductStock> {
  return apiRequest<ProductStock>(`/api/v1/products/${productId}/stock`);
}

export function updateProductStockConfig(
  productId: number,
  input: ProductStockConfigInput,
): Promise<ProductStock> {
  return apiRequest<ProductStock>(`/api/v1/products/${productId}/stock`, {
    method: "PATCH",
    body: JSON.stringify({ product_stock: input }),
  });
}

export function updateProductStockPriority(
  productId: number,
  input: ProductStockPriorityInput,
): Promise<ProductStock> {
  return apiRequest<ProductStock>(`/api/v1/products/${productId}/stock/priority`, {
    method: "PATCH",
    body: JSON.stringify({ product_stock: input }),
  });
}
