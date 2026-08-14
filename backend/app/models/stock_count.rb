class StockCount < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :counted_at, presence: true

  after_save :sync_product_stock!

  private

  # A purchase never changes stock — only a count does. ProductStock#current_quantity
  # always mirrors whichever count is most recent by counted_at (ties broken by id),
  # so editing an older count (a correction) never clobbers a newer one that already
  # superseded it, and creating a new count always takes over as expected.
  def sync_product_stock!
    latest = product.stock_counts.order(counted_at: :desc, id: :desc).first
    return unless latest

    stock = product.product_stock || product.build_product_stock
    previous_quantity = stock.current_quantity
    stock.update!(current_quantity: latest.quantity)

    record_current_quantity_audit!(stock, previous_quantity, latest.user) if stock.saved_change_to_current_quantity?
  end

  # Bloco Histórico: only when the value actually changed (dirty tracking
  # already skips this when a new count just confirms the same quantity —
  # "Estoque atual = 10, Nova contagem = 10" must never create a fake entry).
  # Attributed to *this* count's user, not necessarily the currently
  # authenticated request — correct either way since a StockCount can only
  # ever be created/edited by the user who owns it.
  def record_current_quantity_audit!(stock, previous_quantity, acting_user)
    StockAuditEntry.create!(
      product: product,
      user: acting_user,
      field: "current_quantity",
      previous_value: previous_quantity&.to_s,
      new_value: stock.current_quantity.to_s
    )
  end
end
