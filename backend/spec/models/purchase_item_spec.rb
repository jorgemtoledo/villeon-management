require "rails_helper"

RSpec.describe PurchaseItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:purchase) }
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe "quantity precision" do
    it "preserves four decimal places (e.g. 0.1234 kg is not rounded away)" do
      item = create(:purchase_item, quantity: 0.1234, unit_price: 10)

      expect(item.reload.quantity).to eq(BigDecimal("0.1234"))
    end
  end

  describe "total_price" do
    it "is always calculated from quantity * unit_price, even when left blank" do
      item = build(:purchase_item, quantity: 3, unit_price: 5.5, total_price: nil)

      item.valid?

      expect(item.total_price).to eq(BigDecimal("16.50"))
    end

    it "overwrites any explicitly provided value to guarantee consistency" do
      item = build(:purchase_item, quantity: 3, unit_price: 5.5, total_price: 999)

      item.valid?

      expect(item.total_price).to eq(BigDecimal("16.50"))
    end

    it "stays consistent with quantity and unit_price after being persisted" do
      item = create(:purchase_item, quantity: 2.5, unit_price: 3.33)

      expect(item.reload.total_price).to eq((item.quantity * item.unit_price).round(2))
    end

    it "is enforced at the database level for non-negative total_price" do
      item = create(:purchase_item)

      expect {
        item.update_column(:total_price, -1)
      }.to raise_error(ActiveRecord::StatementInvalid, /purchase_items_total_price_check/)
    end
  end

  it "is enforced at the database level for positive quantity" do
    item = create(:purchase_item)

    expect {
      item.update_column(:quantity, 0)
    }.to raise_error(ActiveRecord::StatementInvalid, /purchase_items_quantity_check/)
  end

  it "blocks deletion of a product still referenced by a purchase_item" do
    product = create(:product)
    create(:purchase_item, product: product)

    expect { product.destroy }.not_to change(Product, :count)
    expect(product.errors[:base]).to be_present
  end
end
