FactoryBot.define do
  factory :stock_audit_entry do
    product
    user
    field { "current_quantity" }
    previous_value { "10" }
    new_value { "5" }
  end
end
