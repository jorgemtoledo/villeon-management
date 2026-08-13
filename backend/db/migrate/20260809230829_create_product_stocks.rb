class CreateProductStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :product_stocks do |t|
      t.references :product, null: false, foreign_key: true, index: { unique: true }

      t.decimal :current_quantity, precision: 12, scale: 3, null: false, default: 0
      t.decimal :minimum_quantity, precision: 12, scale: 3, null: false, default: 0
      t.decimal :ideal_quantity, precision: 12, scale: 3, null: false, default: 0

      t.timestamps

      t.check_constraint "current_quantity >= 0", name: "product_stocks_current_quantity_check"
      t.check_constraint "minimum_quantity >= 0", name: "product_stocks_minimum_quantity_check"
      t.check_constraint "ideal_quantity >= 0", name: "product_stocks_ideal_quantity_check"
    end
  end
end
