FactoryBot.define do
  factory :product_supplier do
    product
    supplier
    preferred { false }
    supplier_product_code { nil }
    notes { nil }
  end
end
