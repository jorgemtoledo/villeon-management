class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :supplier, null: false, foreign_key: true

      t.datetime :purchased_at, null: false
      # Not unique: the client's historical spreadsheet already shows apparent
      # duplicate/reissued invoice numbers — reconciliation is a human review
      # task, never an automatic block on import.
      t.string :invoice_number
      t.decimal :total_amount, precision: 12, scale: 2, null: false
      t.text :notes

      t.timestamps

      t.check_constraint "total_amount >= 0", name: "purchases_total_amount_check"
    end

    add_index :purchases, :purchased_at
    add_index :purchases, :invoice_number
  end
end
