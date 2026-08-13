class StockCountSerializer
  def self.call(stock_count)
    new(stock_count).call
  end

  def initialize(stock_count)
    @stock_count = stock_count
  end

  def call
    {
      id: stock_count.id,
      product: { id: stock_count.product.id, name: stock_count.product.name, code: stock_count.product.code },
      user: { id: stock_count.user.id, name: stock_count.user.name },
      quantity: stock_count.quantity,
      counted_at: stock_count.counted_at,
      created_at: stock_count.created_at,
      updated_at: stock_count.updated_at
    }
  end

  private

  attr_reader :stock_count
end
