require "rails_helper"

RSpec.describe ProductSupplier, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:supplier) }
  end

  describe "product + supplier uniqueness" do
    it "rejects a duplicate pair via Rails validation" do
      product = create(:product)
      supplier = create(:supplier)
      create(:product_supplier, product: product, supplier: supplier)

      duplicate = build(:product_supplier, product: product, supplier: supplier)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end

    it "is enforced at the database level as defense in depth" do
      product = create(:product)
      supplier = create(:supplier)
      create(:product_supplier, product: product, supplier: supplier)

      duplicate = build(:product_supplier, product: product, supplier: supplier)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same product with a different supplier" do
      product = create(:product)
      create(:product_supplier, product: product, supplier: create(:supplier))

      other = build(:product_supplier, product: product, supplier: create(:supplier))

      expect(other).to be_valid
    end

    it "allows the same supplier with a different product" do
      supplier = create(:supplier)
      create(:product_supplier, product: create(:product), supplier: supplier)

      other = build(:product_supplier, product: create(:product), supplier: supplier)

      expect(other).to be_valid
    end
  end
end
