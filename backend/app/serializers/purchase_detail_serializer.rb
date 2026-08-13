class PurchaseDetailSerializer
  def self.call(purchase)
    new(purchase).call
  end

  def initialize(purchase)
    @purchase = purchase
  end

  def call
    {
      id: purchase.id,
      purchased_at: purchase.purchased_at,
      supplier: { id: purchase.supplier.id, name: purchase.supplier.name },
      total_amount: purchase.total_amount,
      invoice_number: purchase.invoice_number,
      items: purchase.purchase_items.map { |item| item_json(item) }
    }
  end

  private

  attr_reader :purchase

  def item_json(item)
    {
      id: item.id,
      product: { id: item.product.id, name: item.product.name, code: item.product.code },
      quantity: item.quantity,
      unit: unit_reference(item.product.purchase_unit),
      unit_price: item.unit_price,
      total_price: item.total_price
    }
  end

  def unit_reference(unit)
    return nil if unit.nil?

    { id: unit.id, name: unit.name, abbreviation: unit.abbreviation }
  end
end
