# Serializes a ProductSupplier (the pivot) together with the referenced
# Supplier's own identifying fields, for the product-scoped endpoints under
# /api/v1/products/:product_id/suppliers. Mirror of SupplierProductSerializer,
# same pivot from the other direction (product -> its suppliers).
class ProductSupplierSerializer
  def self.call(product_supplier)
    new(product_supplier).call
  end

  def initialize(product_supplier)
    @product_supplier = product_supplier
  end

  def call
    {
      id: product_supplier.id,
      supplier: { id: supplier.id, name: supplier.name, cnpj: supplier.cnpj },
      preferred: product_supplier.preferred,
      supplier_product_code: product_supplier.supplier_product_code,
      notes: product_supplier.notes
    }
  end

  private

  attr_reader :product_supplier

  def supplier
    product_supplier.supplier
  end
end
