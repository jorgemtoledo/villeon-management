class Category < ApplicationRecord
  has_many :subcategories, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
