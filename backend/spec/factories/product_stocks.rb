FactoryBot.define do
  factory :product_stock do
    product
    current_quantity { 10 }
    minimum_quantity { 2 }
    ideal_quantity { 15 }
  end
end
