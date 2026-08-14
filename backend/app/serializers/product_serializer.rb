class ProductSerializer
  def self.call(product, product_suppliers_count:)
    new(product, product_suppliers_count).call
  end

  def initialize(product, product_suppliers_count)
    @product = product
    @product_suppliers_count = product_suppliers_count
  end

  def call
    {
      id: product.id,
      name: product.name,
      code: product.code,
      colibri_code: product.colibri_code,
      conversion_factor: product.conversion_factor,
      active: product.active,
      sector: reference(product.sector),
      category: reference(product.category),
      subcategory: reference(product.subcategory),
      purchase_unit: unit_reference(product.purchase_unit),
      stock_unit: unit_reference(product.stock_unit),
      product_suppliers_count: product_suppliers_count,
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end

  private

  attr_reader :product, :product_suppliers_count

  def reference(record)
    return nil if record.nil?

    { id: record.id, name: record.name }
  end

  def unit_reference(unit)
    return nil if unit.nil?

    { id: unit.id, name: unit.name, abbreviation: unit.abbreviation }
  end
end
