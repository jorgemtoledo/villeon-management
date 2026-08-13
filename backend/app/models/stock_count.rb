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
    stock.update!(current_quantity: latest.quantity)
  end
end
