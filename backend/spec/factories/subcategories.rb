FactoryBot.define do
  factory :subcategory do
    sequence(:code) { |n| "SUB#{n}" }
    name { "Subcategoria de exemplo" }
    active { true }
  end
end
