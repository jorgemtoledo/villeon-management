FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@villeon.example.com" }
    password { "password123" }
    name { Faker::Name.name }
    role { "operator" }
    active { true }
    sector { nil }
  end
end
