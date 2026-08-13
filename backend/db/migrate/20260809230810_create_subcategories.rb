class CreateSubcategories < ActiveRecord::Migration[8.1]
  def change
    create_table :subcategories do |t|
      t.references :category, null: false, foreign_key: true
      t.string :code, null: false
      # Description pending from the client (Felipe) for several of the spreadsheet's
      # legacy subcategory codes — nullable until confirmed, code alone identifies the row.
      t.string :name
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :subcategories, %i[category_id code], unique: true
  end
end
