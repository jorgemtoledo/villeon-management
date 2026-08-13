class Supplier < ApplicationRecord
  has_many :product_suppliers, dependent: :restrict_with_error
  has_many :products, through: :product_suppliers
  has_many :purchases, dependent: :restrict_with_error

  before_validation :normalize_cnpj

  validates :name, presence: true
  validates :cnpj, uniqueness: true, allow_nil: true, cnpj: true

  private

  # Blank input (from a form field left empty) becomes nil, not "" — keeps
  # it consistent with `allow_nil` instead of uniqueness comparing empty
  # strings against each other. A real value is stripped down to its 14
  # digits so "12.345.678/0001-99" and "12345678000199" are the same CNPJ.
  def normalize_cnpj
    self.cnpj = cnpj.present? ? Cnpj.normalize(cnpj) : nil
  end
end
