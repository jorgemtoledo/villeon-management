class ProductStock < ApplicationRecord
  belongs_to :product, inverse_of: :product_stock

  validates :product_id, uniqueness: true
  validates :current_quantity, :minimum_quantity, :ideal_quantity,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :ideal_not_below_minimum

  private

  # Matches the "Catálogo Mestre" conditional formatting rule that flags
  # ideal < mínimo as bad data — here it's a hard validation instead, since
  # this is the endpoint that lets it be configured deliberately (Bloco 6G
  # Parte 2), not just imported from an already-inconsistent spreadsheet row.
  def ideal_not_below_minimum
    return if minimum_quantity.blank? || ideal_quantity.blank?
    return if ideal_quantity >= minimum_quantity

    errors.add(:ideal_quantity, "não pode ser menor que o estoque mínimo")
  end
end
