class ProductSerializer
  def self.call(product)
    new(product).call
  end

  def initialize(product)
    @product = product
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
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end

  private

  attr_reader :product

  def reference(record)
    return nil if record.nil?

    { id: record.id, name: record.name }
  end

  def unit_reference(unit)
    return nil if unit.nil?

    { id: unit.id, name: unit.name, abbreviation: unit.abbreviation }
  end
end
