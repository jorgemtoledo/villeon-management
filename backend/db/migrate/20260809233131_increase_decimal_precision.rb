class IncreaseDecimalPrecision < ActiveRecord::Migration[8.1]
  # Stock/purchase quantities need at least 4 decimal places (unit_price and
  # conversion_factor already had 4; totals stay at 2, as monetary values).
  # Explicit up/down (not `change`) because `change_column` cannot infer the
  # previous scale on its own for a clean rollback.
  def up
    change_column :product_stocks, :current_quantity, :decimal, precision: 12, scale: 4, null: false, default: 0
    change_column :product_stocks, :minimum_quantity, :decimal, precision: 12, scale: 4, null: false, default: 0
    change_column :product_stocks, :ideal_quantity, :decimal, precision: 12, scale: 4, null: false, default: 0
    change_column :stock_counts, :quantity, :decimal, precision: 12, scale: 4, null: false
    change_column :purchase_items, :quantity, :decimal, precision: 12, scale: 4, null: false
  end

  def down
    change_column :product_stocks, :current_quantity, :decimal, precision: 12, scale: 3, null: false, default: 0
    change_column :product_stocks, :minimum_quantity, :decimal, precision: 12, scale: 3, null: false, default: 0
    change_column :product_stocks, :ideal_quantity, :decimal, precision: 12, scale: 3, null: false, default: 0
    change_column :stock_counts, :quantity, :decimal, precision: 12, scale: 3, null: false
    change_column :purchase_items, :quantity, :decimal, precision: 12, scale: 3, null: false
  end
end
