class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :products, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: { scope: :category_id }
end
