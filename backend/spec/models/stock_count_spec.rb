require "rails_helper"

RSpec.describe StockCount, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:counted_at) }
  end

  it "keeps every count as its own row instead of overwriting the previous one" do
    product = create(:product)
    user = create(:user)

    create(:stock_count, product: product, user: user, quantity: 10, counted_at: 2.days.ago)
    create(:stock_count, product: product, user: user, quantity: 8, counted_at: 1.day.ago)

    expect(product.stock_counts.count).to eq(2)
  end

  describe "syncing ProductStock#current_quantity" do
    it "creates a ProductStock the first time a product is counted" do
      product = create(:product)

      expect(product.product_stock).to be_nil

      create(:stock_count, product: product, quantity: 42)

      expect(product.reload.product_stock.current_quantity).to eq(BigDecimal("42"))
    end

    it "updates current_quantity to a newer count, keeping minimum/ideal untouched" do
      product = create(:product)
      stock = create(:product_stock, product: product, current_quantity: 10, minimum_quantity: 3, ideal_quantity: 20)

      create(:stock_count, product: product, quantity: 7, counted_at: 1.hour.ago)

      expect(stock.reload.current_quantity).to eq(BigDecimal("7"))
      expect(stock.minimum_quantity).to eq(BigDecimal("3"))
      expect(stock.ideal_quantity).to eq(BigDecimal("20"))
    end

    it "does not let an older count (edited later) override a newer one" do
      product = create(:product)
      create(:stock_count, product: product, quantity: 10, counted_at: 2.days.ago)
      newer = create(:stock_count, product: product, quantity: 8, counted_at: 1.day.ago)

      older = product.stock_counts.find_by(quantity: 10)
      older.update!(quantity: 999)

      expect(product.reload.product_stock.current_quantity).to eq(newer.quantity)
    end

    it "picks up an edit to the currently-latest count" do
      product = create(:product)
      latest = create(:stock_count, product: product, quantity: 8, counted_at: 1.day.ago)

      latest.update!(quantity: 15)

      expect(product.reload.product_stock.current_quantity).to eq(BigDecimal("15"))
    end
  end

  describe "auditing current_quantity changes (Bloco Histórico)" do
    it "creates a StockAuditEntry when a new count actually changes the current quantity" do
      product = create(:product)
      user = create(:user)
      create(:product_stock, product: product, current_quantity: 12)

      expect {
        create(:stock_count, product: product, user: user, quantity: 5, counted_at: 1.hour.from_now)
      }.to change(StockAuditEntry, :count).by(1)

      entry = StockAuditEntry.last
      expect(entry.product).to eq(product)
      expect(entry.user).to eq(user)
      expect(entry.field).to eq("current_quantity")
      expect(entry.previous_value).to eq("12.0")
      expect(entry.new_value).to eq("5.0")
    end

    it "does not create a fake entry when a new count confirms the same quantity" do
      product = create(:product)
      create(:product_stock, product: product, current_quantity: 10)

      expect {
        create(:stock_count, product: product, quantity: 10, counted_at: 1.hour.from_now)
      }.not_to change(StockAuditEntry, :count)
    end

    it "logs the first-ever count for a product (previous value is the zero default)" do
      product = create(:product)
      user = create(:user)

      create(:stock_count, product: product, user: user, quantity: 8)

      entry = StockAuditEntry.last
      expect(entry.field).to eq("current_quantity")
      expect(entry.previous_value).to eq("0.0")
      expect(entry.new_value).to eq("8.0")
    end

    it "attributes the entry to the count's own user, not a global current user" do
      product = create(:product)
      counter = create(:user, name: "Luiz")
      create(:product_stock, product: product, current_quantity: 1)

      create(:stock_count, product: product, user: counter, quantity: 2, counted_at: 1.hour.from_now)

      expect(StockAuditEntry.last.user).to eq(counter)
    end

    it "does not touch StockAuditEntry when editing an older count that no longer wins" do
      product = create(:product)
      create(:stock_count, product: product, quantity: 10, counted_at: 2.days.ago)
      newer = create(:stock_count, product: product, quantity: 8, counted_at: 1.day.ago)
      older = product.stock_counts.find_by(quantity: 10)

      expect {
        older.update!(quantity: 999)
      }.not_to change(StockAuditEntry, :count)

      expect(product.reload.product_stock.current_quantity).to eq(newer.quantity)
    end
  end
end
