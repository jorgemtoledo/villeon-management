class ProductSupplier < ApplicationRecord
  belongs_to :product
  belongs_to :supplier

  validates :product_id, uniqueness: { scope: :supplier_id }
end
