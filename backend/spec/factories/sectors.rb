FactoryBot.define do
  factory :sector do
    sequence(:name) { |n| "Setor #{n}" }
    active { true }
  end
end
