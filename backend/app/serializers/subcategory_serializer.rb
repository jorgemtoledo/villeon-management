class SubcategorySerializer
  # Only id/code — the client's own code IS the classification (Bloco
  # Subcategoria), never translated or paired with an invented description.
  def self.call(subcategory)
    new(subcategory).call
  end

  def initialize(subcategory)
    @subcategory = subcategory
  end

  def call
    {
      id: subcategory.id,
      code: subcategory.code
    }
  end

  private

  attr_reader :subcategory
end
