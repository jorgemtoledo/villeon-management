FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Fornecedor #{n}" }
    cnpj { nil }
    active { true }

    trait :with_cnpj do
      sequence(:cnpj) { |n| CnpjHelper.generate(n) }
    end
  end
end
