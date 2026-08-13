FactoryBot.define do
  factory :purchase_item do
    purchase
    product
    quantity { 10 }
    unit_price { 5.5 }
    # total_price is intentionally left unset — PurchaseItem#calculate_total_price
    # (before_validation) derives it from quantity * unit_price.
  end
end
