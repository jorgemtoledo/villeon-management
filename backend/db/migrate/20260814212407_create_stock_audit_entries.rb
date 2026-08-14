class CreateStockAuditEntries < ActiveRecord::Migration[8.1]
  # Auditoria das alterações de estoque (Bloco Histórico) — imutável, nunca
  # atualizada/excluída, por isso só `created_at` (sem `updated_at`: nada
  # nesta tabela é esperado mudar depois de escrito).
  def change
    create_table :stock_audit_entries do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      # "current_quantity" | "priority" | "needs_advance_order" — os únicos
      # três campos auditáveis (Bloco Histórico), nunca minimum/ideal.
      t.string :field, null: false
      # Sempre string (mesmo pra current_quantity, que é decimal, e
      # needs_advance_order, que é boolean) — este registro é só pra exibição
      # histórica, nunca reconstrução programática do valor tipado original.
      t.string :previous_value
      t.string :new_value
      t.datetime :created_at, null: false
    end

    add_index :stock_audit_entries, [ :product_id, :created_at ]
    add_index :stock_audit_entries, :field
  end
end
