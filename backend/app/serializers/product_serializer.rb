class ProductSerializer
  # last_purchase: whatever ProductsController#last_purchases_for returns for
  # this product's id — an object responding to #unit_price/#purchased_at
  # (see that method), or nil for a product never purchased. Never a
  # persisted column on Product; always derived from Purchase/PurchaseItem
  # at read time (Bloco 6H.4 analysis — matches the source spreadsheet's own
  # T/U columns, which are formulas, not stored values).
  def self.call(product, product_suppliers_count:, last_purchase: nil)
    new(product, product_suppliers_count, last_purchase).call
  end

  def initialize(product, product_suppliers_count, last_purchase)
    @product = product
    @product_suppliers_count = product_suppliers_count
    @last_purchase = last_purchase
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
      subcategory: subcategory_reference(product.subcategory),
      purchase_unit: unit_reference(product.purchase_unit),
      stock_unit: unit_reference(product.stock_unit),
      product_suppliers_count: product_suppliers_count,
      last_purchase_price: last_purchase&.unit_price,
      last_purchase_date: last_purchase&.purchased_at,
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end

  private

  attr_reader :product, :product_suppliers_count, :last_purchase

  def reference(record)
    return nil if record.nil?

    { id: record.id, name: record.name }
  end

  # Subcategory is exposed by `code`, not `name` — the client's own code
  # (Bloco Subcategoria) IS the classification, never an invented label.
  def subcategory_reference(subcategory)
    return nil if subcategory.nil?

    { id: subcategory.id, code: subcategory.code }
  end

  def unit_reference(unit)
    return nil if unit.nil?

    { id: unit.id, name: unit.name, abbreviation: unit.abbreviation }
  end
end
