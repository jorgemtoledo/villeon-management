class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  before_validation :calculate_total_price

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  private

  def calculate_total_price
    return if quantity.blank? || unit_price.blank?

    self.total_price = (quantity * unit_price).round(2)
  end
end
