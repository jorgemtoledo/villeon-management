class Subcategory < ApplicationRecord
  belongs_to :category, optional: true
  has_many :products, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
end
