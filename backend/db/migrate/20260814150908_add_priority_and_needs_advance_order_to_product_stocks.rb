class AddPriorityAndNeedsAdvanceOrderToProductStocks < ActiveRecord::Migration[8.1]
  def change
    # Both nullable, no default: nil means "never configured", distinct from
    # an explicit "low priority" / "false" — same reasoning as R's 2 blank
    # cells in the source spreadsheet (Bloco 6G Parte 4 analysis). Not a
    # backfill — every row starts nil regardless of the spreadsheet's values.
    add_column :product_stocks, :priority, :string
    add_column :product_stocks, :needs_advance_order, :boolean

    add_check_constraint :product_stocks, "priority IN ('critical', 'normal', 'low')",
                          name: "product_stocks_priority_check"
  end
end
