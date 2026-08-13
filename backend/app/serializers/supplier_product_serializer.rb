# Serializes a ProductSupplier (the pivot) together with the referenced
# Product's own identifying fields, for the read-only
# GET /api/v1/suppliers/:id/products endpoint.
class SupplierProductSerializer
  def self.call(product_supplier)
    new(product_supplier).call
  end

  def initialize(product_supplier)
    @product_supplier = product_supplier
  end

  def call
    {
      id: product.id,
      name: product.name,
      code: product.code,
      supplier_product_code: product_supplier.supplier_product_code,
      preferred: product_supplier.preferred,
      notes: product_supplier.notes
    }
  end

  private

  attr_reader :product_supplier

  def product
    product_supplier.product
  end
end
