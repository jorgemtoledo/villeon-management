class MakeProductsCategoryIdOptional < ActiveRecord::Migration[8.1]
  # The client's real Category taxonomy isn't defined yet (see Bloco 3A) — a
  # required category_id would block product creation with no honest value
  # to put there. Revisit via migration once Felipe confirms the taxonomy.
  def up
    change_column_null :products, :category_id, true
  end

  def down
    change_column_null :products, :category_id, false
  end
end
