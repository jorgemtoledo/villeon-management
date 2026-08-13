class CreateStockCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_counts do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.datetime :counted_at, null: false

      t.timestamps

      t.check_constraint "quantity >= 0", name: "stock_counts_quantity_check"
    end

    add_index :stock_counts, :counted_at
  end
end
