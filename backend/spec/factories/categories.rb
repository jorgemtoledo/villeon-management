FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Categoria #{n}" }
    active { true }
  end
end
