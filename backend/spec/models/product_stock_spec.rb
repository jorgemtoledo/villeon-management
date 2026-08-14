require "rails_helper"

RSpec.describe ProductStock, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:current_quantity) }
    it { is_expected.to validate_presence_of(:minimum_quantity) }
    it { is_expected.to validate_presence_of(:ideal_quantity) }
  end

  describe "quantities" do
    it { is_expected.to validate_numericality_of(:current_quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:minimum_quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:ideal_quantity).is_greater_than_or_equal_to(0) }

    it "preserves four decimal places" do
      stock = create(:product_stock, current_quantity: 12.3456)

      expect(stock.reload.current_quantity).to eq(BigDecimal("12.3456"))
    end
  end

  describe "one-to-one with product" do
    it "rejects a second stock row for the same product via Rails validation" do
      product = create(:product)
      create(:product_stock, product: product)

      duplicate = build(:product_stock, product: product)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end

    it "is enforced at the database level as defense in depth" do
      product = create(:product)
      create(:product_stock, product: product)

      duplicate = build(:product_stock, product: product)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  it "is enforced at the database level for non-negative current_quantity" do
    stock = create(:product_stock)

    expect {
      stock.update_column(:current_quantity, -1)
    }.to raise_error(ActiveRecord::StatementInvalid, /product_stocks_current_quantity_check/)
  end

  describe "priority" do
    it "accepts the three valid values" do
      %w[critical normal low].each do |value|
        stock = build(:product_stock, priority: value)
        expect(stock).to be_valid
      end
    end

    it "is nil by default (never configured)" do
      stock = create(:product_stock)

      expect(stock.priority).to be_nil
    end

    it "rejects an invalid value at the database level as defense in depth" do
      stock = create(:product_stock)

      expect {
        stock.update_column(:priority, "urgent")
      }.to raise_error(ActiveRecord::StatementInvalid, /product_stocks_priority_check/)
    end
  end

  describe "needs_advance_order" do
    it "is nil by default (never configured), distinct from explicitly false" do
      stock = create(:product_stock)

      expect(stock.needs_advance_order).to be_nil
    end

    it "accepts true and false explicitly" do
      expect(build(:product_stock, needs_advance_order: true)).to be_valid
      expect(build(:product_stock, needs_advance_order: false)).to be_valid
    end
  end

  describe "ideal must not be below minimum" do
    it "is invalid when ideal is less than minimum" do
      stock = build(:product_stock, minimum_quantity: 10, ideal_quantity: 5)

      expect(stock).not_to be_valid
      expect(stock.errors[:ideal_quantity]).to be_present
    end

    it "is valid when ideal equals minimum" do
      stock = build(:product_stock, minimum_quantity: 10, ideal_quantity: 10)

      expect(stock).to be_valid
    end

    it "is valid when ideal is greater than minimum" do
      stock = build(:product_stock, minimum_quantity: 5, ideal_quantity: 10)

      expect(stock).to be_valid
    end
  end
end
