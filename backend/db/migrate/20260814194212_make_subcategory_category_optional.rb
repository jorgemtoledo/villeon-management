class MakeSubcategoryCategoryOptional < ActiveRecord::Migration[8.1]
  # Bloco: Subcategoria do Catálogo Mestre. The spreadsheet's "Subcategoria"
  # column (D) is a flat list of 25 free-standing codes with no parent
  # category anywhere in the source data — Category (a separate, still-empty
  # taxonomy) doesn't apply here. Dropping the mandatory FK lets Subcategory
  # exist on its own; Category itself is untouched, still available if the
  # client ever confirms a real hierarchy.
  def change
    remove_index :subcategories, %i[category_id code]
    change_column_null :subcategories, :category_id, true
    add_index :subcategories, :code, unique: true
  end
end
