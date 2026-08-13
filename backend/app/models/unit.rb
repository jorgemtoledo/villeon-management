class Unit < ApplicationRecord
  has_many :products_as_purchase_unit, class_name: "Product", foreign_key: :purchase_unit_id,
                                        inverse_of: :purchase_unit, dependent: :restrict_with_error
  has_many :products_as_stock_unit, class_name: "Product", foreign_key: :stock_unit_id,
                                     inverse_of: :stock_unit, dependent: :restrict_with_error

  validates :name, presence: true
  validates :abbreviation, presence: true, uniqueness: true
end
