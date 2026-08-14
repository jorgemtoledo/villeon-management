// Mirrors ProductSupplierSerializer#call exactly — keep in sync with the
// Rails serializer. The pivot (ProductSupplier) plus the referenced
// Supplier's own identifying fields, from the product's perspective.
export interface ProductSupplierLink {
  id: number;
  supplier: { id: number; name: string; cnpj: string | null };
  preferred: boolean;
  supplier_product_code: string | null;
  notes: string | null;
}

// Mirrors Api::V1::ProductSuppliersController#product_supplier_params.
export interface ProductSupplierInput {
  supplier_id: number;
  preferred?: boolean;
  supplier_product_code?: string | null;
  notes?: string | null;
}
