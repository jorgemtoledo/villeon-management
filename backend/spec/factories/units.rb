FactoryBot.define do
  factory :unit do
    sequence(:name) { |n| "Unidade #{n}" }
    sequence(:abbreviation) { |n| "UN#{n}" }
    active { true }
  end
end
