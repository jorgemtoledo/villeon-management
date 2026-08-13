class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :code, null: false
      # Free text in the client's spreadsheet today (embedded in "Observações"); kept
      # non-unique here on purpose until the Colibri integration block validates the data.
      t.string :colibri_code

      t.references :sector, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :subcategory, null: true, foreign_key: true
      t.references :purchase_unit, null: false, foreign_key: { to_table: :units }
      t.references :stock_unit, null: false, foreign_key: { to_table: :units }

      t.decimal :conversion_factor, precision: 12, scale: 4, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps

      t.check_constraint "conversion_factor > 0", name: "products_conversion_factor_check"
    end

    add_index :products, :code, unique: true
    add_index :products, :colibri_code
  end
end
