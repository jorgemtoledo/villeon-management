FactoryBot.define do
  factory :stock_count do
    product
    user
    quantity { 5 }
    counted_at { Time.current }
  end
end
