class PurchaseSerializer
  def self.call(purchase, items_count:)
    new(purchase, items_count).call
  end

  def initialize(purchase, items_count)
    @purchase = purchase
    @items_count = items_count
  end

  def call
    {
      id: purchase.id,
      purchased_at: purchase.purchased_at,
      supplier: { id: purchase.supplier.id, name: purchase.supplier.name },
      total_amount: purchase.total_amount,
      items_count: items_count
    }
  end

  private

  attr_reader :purchase, :items_count
end
