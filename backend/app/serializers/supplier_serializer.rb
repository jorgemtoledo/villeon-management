class SupplierSerializer
  def self.call(supplier, products_count:)
    new(supplier, products_count).call
  end

  def initialize(supplier, products_count)
    @supplier = supplier
    @products_count = products_count
  end

  def call
    {
      id: supplier.id,
      name: supplier.name,
      cnpj: supplier.cnpj,
      active: supplier.active,
      products_count: products_count,
      created_at: supplier.created_at,
      updated_at: supplier.updated_at
    }
  end

  private

  attr_reader :supplier, :products_count
end
