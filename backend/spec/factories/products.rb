FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Produto #{n}" }
    sequence(:code) { |n| "PROD-#{n}" }
    colibri_code { nil }
    sector
    category
    subcategory { nil }
    association :purchase_unit, factory: :unit
    association :stock_unit, factory: :unit
    conversion_factor { 1 }
    active { true }
  end
end
