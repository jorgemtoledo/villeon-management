class ProductStockSerializer
  def self.call(product, counted: nil)
    new(product, counted: counted).call
  end

  def initialize(product, counted: nil)
    @product = product
    @counted = counted
  end

  def call
    {
      product: { id: product.id, name: product.name, code: product.code, active: product.active },
      sector: reference(product.sector),
      purchase_unit: unit_reference(product.purchase_unit),
      stock_unit: unit_reference(product.stock_unit),
      **StockCalculator.call(product, counted: @counted)
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
