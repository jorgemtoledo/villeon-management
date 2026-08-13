class Purchase < ApplicationRecord
  belongs_to :supplier
  has_many :purchase_items, dependent: :restrict_with_error

  validates :purchased_at, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
