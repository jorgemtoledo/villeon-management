import { apiRequest } from "@/lib/api/client";
import type { ProductSupplierLink, ProductSupplierInput } from "@/types/product-supplier";

export function fetchProductSuppliers(productId: number): Promise<ProductSupplierLink[]> {
  return apiRequest<ProductSupplierLink[]>(`/api/v1/products/${productId}/suppliers`);
}

export function createProductSupplier(
  productId: number,
  input: ProductSupplierInput,
): Promise<ProductSupplierLink> {
  return apiRequest<ProductSupplierLink>(`/api/v1/products/${productId}/suppliers`, {
    method: "POST",
    body: JSON.stringify({ product_supplier: input }),
  });
}

export function deleteProductSupplier(productId: number, linkId: number): Promise<void> {
  return apiRequest<void>(`/api/v1/products/${productId}/suppliers/${linkId}`, {
    method: "DELETE",
  });
}

export function preferProductSupplier(productId: number, linkId: number): Promise<ProductSupplierLink> {
  return apiRequest<ProductSupplierLink>(`/api/v1/products/${productId}/suppliers/${linkId}/prefer`, {
    method: "PATCH",
  });
}
