class StockAuditEntry < ApplicationRecord
  FIELDS = %w[current_quantity priority needs_advance_order].freeze

  belongs_to :product
  belongs_to :user

  validates :field, presence: true, inclusion: { in: FIELDS }

  # Auditoria imutável (Bloco Histórico) — nunca editada nem excluída, nem
  # por engano de código futuro. Só bloqueia update/destroy; create continua
  # livre (é o único jeito de um registro passar a existir).
  before_update { raise ActiveRecord::ReadOnlyRecord, "StockAuditEntry é um registro de auditoria imutável" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "StockAuditEntry é um registro de auditoria imutável" }
end
