require "rails_helper"

# Every scenario here mirrors, on purpose, the real "Catálogo Mestre" formulas
# extracted from the client's .xlsx (see app/services/stock_calculator.rb for
# the literal formula text) — not invented business logic.
RSpec.describe StockCalculator do
  describe ".call" do
    context "product was never configured (no ProductStock row at all)" do
      it "returns nao_contado with every quantity nil" do
        product = create(:product)

        result = described_class.call(product)

        expect(result).to eq(
          current_quantity: nil,
          minimum_quantity: nil,
          ideal_quantity: nil,
          replenishment_quantity: nil,
          purchase_quantity: nil,
          status: "nao_contado",
          minimum_configured: false
        )
      end
    end

    context "ProductStock is configured (minimum/ideal) but was never counted" do
      it "still reports nao_contado, but exposes the configured minimum/ideal" do
        product = create(:product)
        create(:product_stock, product: product, minimum_quantity: 5, ideal_quantity: 20)

        result = described_class.call(product, counted: false)

        expect(result[:status]).to eq("nao_contado")
        expect(result[:current_quantity]).to be_nil
        expect(result[:replenishment_quantity]).to be_nil
        expect(result[:purchase_quantity]).to be_nil
        expect(result[:minimum_quantity]).to eq(BigDecimal("5"))
        expect(result[:ideal_quantity]).to eq(BigDecimal("20"))
        expect(result[:minimum_configured]).to be true
      end

      it "defaults counted: to a real stock_counts.exists? check when not given explicitly" do
        product = create(:product, conversion_factor: 1)
        create(:product_stock, product: product, minimum_quantity: 5, ideal_quantity: 20)

        expect(described_class.call(product)[:status]).to eq("nao_contado")

        create(:stock_count, product: product, quantity: 30)

        expect(described_class.call(product)[:status]).to eq("ok")
      end
    end

    context "current quantity is above the minimum" do
      it "needs no replenishment and status is ok" do
        product = create(:product, conversion_factor: 1)
        create(:product_stock, product: product, current_quantity: 10, minimum_quantity: 5, ideal_quantity: 20)

        result = described_class.call(product, counted: true)

        expect(result[:replenishment_quantity]).to eq(BigDecimal("0"))
        expect(result[:purchase_quantity]).to eq(0)
        expect(result[:status]).to eq("ok")
      end
    end

    context "current quantity is at or below the minimum" do
      it "replenishes up to the ideal quantity and flags comprar" do
        product = create(:product, conversion_factor: 1)
        create(:product_stock, product: product, current_quantity: 4, minimum_quantity: 5, ideal_quantity: 20)

        result = described_class.call(product, counted: true)

        expect(result[:replenishment_quantity]).to eq(BigDecimal("16"))
        expect(result[:purchase_quantity]).to eq(16)
        expect(result[:status]).to eq("comprar")
      end

      it "treats current == minimum as needing replenishment too (H<=I, not H<I)" do
        product = create(:product, conversion_factor: 1)
        create(:product_stock, product: product, current_quantity: 5, minimum_quantity: 5, ideal_quantity: 20)

        result = described_class.call(product, counted: true)

        expect(result[:status]).to eq("comprar")
      end
    end

    context "conversion_factor (Rendimento) is not 1" do
      it "rounds the purchase quantity up (ROUNDUP), never down" do
        product = create(:product, conversion_factor: 2)
        create(:product_stock, product: product, current_quantity: 0, minimum_quantity: 5, ideal_quantity: 5)

        result = described_class.call(product, counted: true)

        expect(result[:replenishment_quantity]).to eq(BigDecimal("5"))
        expect(result[:purchase_quantity]).to eq(3)
      end
    end

    context "product is inactive" do
      it "forces status to inativo even if it would otherwise need buying" do
        product = create(:product, active: false, conversion_factor: 1)
        create(:product_stock, product: product, current_quantity: 0, minimum_quantity: 5, ideal_quantity: 20)

        result = described_class.call(product, counted: true)

        expect(result[:status]).to eq("inativo")
      end
    end

    describe "minimum_configured" do
      it "is false when minimum_quantity is zero (never configured)" do
        product = create(:product)
        create(:product_stock, product: product, minimum_quantity: 0)

        expect(described_class.call(product, counted: true)[:minimum_configured]).to be false
      end

      it "is true when minimum_quantity is set" do
        product = create(:product)
        create(:product_stock, product: product, minimum_quantity: 3)

        expect(described_class.call(product, counted: true)[:minimum_configured]).to be true
      end
    end
  end
end
