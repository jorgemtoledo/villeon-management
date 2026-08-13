require "rails_helper"

RSpec.describe Product, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sector) }
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to belong_to(:subcategory).optional }
    it { is_expected.to belong_to(:purchase_unit).class_name("Unit") }
    it { is_expected.to belong_to(:stock_unit).class_name("Unit") }
    it { is_expected.to have_one(:product_stock) }
    it { is_expected.to have_many(:stock_counts) }
    it { is_expected.to have_many(:product_suppliers) }
    it { is_expected.to have_many(:suppliers).through(:product_suppliers) }
    it { is_expected.to have_many(:purchase_items) }
  end

  describe "validations" do
    subject { create(:product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end

  describe "conversion_factor" do
    it "must be positive" do
      product = build(:product, conversion_factor: 0)

      expect(product).not_to be_valid
      expect(product.errors[:conversion_factor]).to be_present
    end

    it "rejects a negative value" do
      product = build(:product, conversion_factor: -1)

      expect(product).not_to be_valid
    end

    it "accepts a fractional factor and preserves precision" do
      product = create(:product, conversion_factor: 0.75)

      expect(product.reload.conversion_factor).to eq(BigDecimal("0.75"))
    end

    it "is enforced at the database level as defense in depth" do
      product = create(:product)

      expect {
        product.update_column(:conversion_factor, -1)
      }.to raise_error(ActiveRecord::StatementInvalid, /products_conversion_factor_check/)
    end
  end

  it "allows creating a product without a category, since the real taxonomy isn't defined yet" do
    product = build(:product, category: nil)

    expect(product).to be_valid
  end

  describe "colibri_code" do
    it "is not required to be unique, since the client's data isn't reliable yet" do
      create(:product, colibri_code: "65")
      other = build(:product, colibri_code: "65")

      expect(other).to be_valid
    end
  end

  it "allows two products to share the same purchase_unit and stock_unit" do
    unit = create(:unit)
    create(:product, purchase_unit: unit, stock_unit: unit)
    other = build(:product, purchase_unit: unit, stock_unit: unit)

    expect(other).to be_valid
  end
end
