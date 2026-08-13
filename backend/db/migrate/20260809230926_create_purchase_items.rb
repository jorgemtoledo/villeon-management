class CreatePurchaseItems < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :unit_price, precision: 12, scale: 4, null: false
      t.decimal :total_price, precision: 12, scale: 2, null: false

      t.timestamps

      t.check_constraint "quantity > 0", name: "purchase_items_quantity_check"
      t.check_constraint "unit_price >= 0", name: "purchase_items_unit_price_check"
      t.check_constraint "total_price >= 0", name: "purchase_items_total_price_check"
    end
  end
end
