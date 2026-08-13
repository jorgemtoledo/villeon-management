FactoryBot.define do
  factory :purchase do
    supplier
    purchased_at { Time.current }
    invoice_number { nil }
    total_amount { 100.0 }
    notes { nil }
  end
end
