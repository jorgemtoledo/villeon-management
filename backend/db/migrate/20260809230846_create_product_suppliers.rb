class CreateProductSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :product_suppliers do |t|
      t.references :product, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true

      t.boolean :preferred, null: false, default: false
      t.string :supplier_product_code
      t.text :notes

      t.timestamps
    end

    add_index :product_suppliers, %i[product_id supplier_id], unique: true
  end
end
