class Product < ApplicationRecord
  belongs_to :sector
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :purchase_unit, class_name: "Unit", inverse_of: :products_as_purchase_unit
  belongs_to :stock_unit, class_name: "Unit", inverse_of: :products_as_stock_unit

  has_one :product_stock, dependent: :restrict_with_error
  has_many :stock_counts, dependent: :restrict_with_error
  has_many :product_suppliers, dependent: :restrict_with_error
  has_many :suppliers, through: :product_suppliers
  has_many :purchase_items, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :conversion_factor, presence: true, numericality: { greater_than: 0 }
end
