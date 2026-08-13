class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :cnpj
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :suppliers, :name
    add_index :suppliers, :cnpj, unique: true
  end
end
