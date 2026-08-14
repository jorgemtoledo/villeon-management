class StockAuditEntrySerializer
  def self.call(entry)
    new(entry).call
  end

  def initialize(entry)
    @entry = entry
  end

  def call
    {
      id: entry.id,
      product: { id: entry.product.id, name: entry.product.name, code: entry.product.code },
      user: { id: entry.user.id, name: entry.user.name },
      field: entry.field,
      previous_value: entry.previous_value,
      new_value: entry.new_value,
      created_at: entry.created_at
    }
  end

  private

  attr_reader :entry
end
