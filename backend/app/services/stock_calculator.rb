# Reproduces the real formulas from "Catálogo Mestre" (columns K/L/M) of the
# client's spreadsheet, extracted verbatim from the .xlsx XML:
#   Reposição (K): =IF(H="","",MAX(0,IF(H<=I,J-H,0)))
#   Comprar   (L): =IF(H="","",IF(OR(G="",G=0),0,ROUNDUP(K/G,0)))
#   Status    (M): =IF(H="","",IF(AND(H<=I,L>0),"COMPRAR","OK"))
# H=Estoque atual, I=Estoque mínimo, J=Estoque ideal, G=Rendimento
# (estoque/compra) == Product#conversion_factor.
#
# STATUS_NOT_COUNTED and STATUS_INACTIVE do not exist in the spreadsheet
# (blank H is just an empty cell there) — they make explicit, for the API,
# states the sheet only implies: a deactivated product (never suggested for
# purchase, regardless of quantities), and a product whose current stock is
# unknown — which, since Bloco 6G Parte 2, is *not* the same thing as "no
# ProductStock row": minimum/ideal can now be configured (structural, admin
# only) before anyone has ever actually counted the shelf. "Counted" means a
# real StockCount exists — never inferred from ProductStock merely existing,
# since its current_quantity defaults to 0 either way.
#
# The MAX(0, ideal-current) clamp in replenishment_quantity mirrors the sheet
# formula exactly, but since ProductStock (Bloco 6G Parte 2) validates
# ideal >= minimum, and this branch only runs when current <= minimum, ideal
# can never actually be below current here for valid data — the clamp is
# defensive, kept for fidelity to the source formula, not because it's
# expected to trigger.
class StockCalculator
  STATUS_NOT_COUNTED = "nao_contado"
  STATUS_OK = "ok"
  STATUS_BUY = "comprar"
  STATUS_INACTIVE = "inativo"

  def self.call(product, counted: nil)
    new(product, counted: counted).call
  end

  def initialize(product, counted: nil)
    @product = product
    @stock = product.product_stock
    @counted = counted.nil? ? product.stock_counts.exists? : counted
  end

  def call
    return not_configured_result if stock.nil?
    return not_counted_result unless counted

    {
      current_quantity: stock.current_quantity,
      minimum_quantity: stock.minimum_quantity,
      ideal_quantity: stock.ideal_quantity,
      replenishment_quantity: replenishment_quantity,
      purchase_quantity: purchase_quantity,
      status: status,
      minimum_configured: minimum_configured?
    }
  end

  private

  attr_reader :product, :stock, :counted

  def below_minimum?
    stock.current_quantity <= stock.minimum_quantity
  end

  def replenishment_quantity
    return BigDecimal("0") unless below_minimum?

    [ stock.ideal_quantity - stock.current_quantity, BigDecimal("0") ].max
  end

  def purchase_quantity
    return 0 if product.conversion_factor.blank? || product.conversion_factor.zero?

    (replenishment_quantity / product.conversion_factor).ceil
  end

  def status
    return STATUS_INACTIVE unless product.active?
    return STATUS_BUY if below_minimum? && purchase_quantity.positive?

    STATUS_OK
  end

  def minimum_configured?
    stock.minimum_quantity.positive?
  end

  # No ProductStock row at all — minimum/ideal were never configured either.
  def not_configured_result
    {
      current_quantity: nil,
      minimum_quantity: nil,
      ideal_quantity: nil,
      replenishment_quantity: nil,
      purchase_quantity: nil,
      status: STATUS_NOT_COUNTED,
      minimum_configured: false
    }
  end

  # ProductStock exists (minimum/ideal may be configured), but no StockCount
  # was ever registered — current stock is genuinely unknown, but the
  # configured targets are still real and worth returning (the Product edit
  # form needs to display/edit them regardless of counting status).
  def not_counted_result
    {
      current_quantity: nil,
      minimum_quantity: stock.minimum_quantity,
      ideal_quantity: stock.ideal_quantity,
      replenishment_quantity: nil,
      purchase_quantity: nil,
      status: STATUS_NOT_COUNTED,
      minimum_configured: minimum_configured?
    }
  end
end
