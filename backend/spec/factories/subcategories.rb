FactoryBot.define do
  factory :subcategory do
    category
    sequence(:code) { |n| "SUB#{n}" }
    name { "Subcategoria de exemplo" }
    active { true }
  end
end
