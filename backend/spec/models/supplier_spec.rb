require "rails_helper"

RSpec.describe Supplier, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:product_suppliers) }
    it { is_expected.to have_many(:products).through(:product_suppliers) }
    it { is_expected.to have_many(:purchases) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "cnpj" do
    it "allows multiple suppliers without a cnpj" do
      create(:supplier, cnpj: nil)
      other = build(:supplier, cnpj: nil)

      expect(other).to be_valid
    end

    it "treats a blank cnpj the same as nil, not as an empty string" do
      supplier = create(:supplier, cnpj: "")

      expect(supplier.cnpj).to be_nil
    end

    it "rejects a duplicate cnpj via Rails validation" do
      create(:supplier, :with_cnpj, cnpj: "11222333000181")
      duplicate = build(:supplier, cnpj: "11222333000181")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:cnpj]).to be_present
    end

    it "is enforced at the database level as defense in depth" do
      create(:supplier, :with_cnpj, cnpj: "11222333000181")
      duplicate = build(:supplier, cnpj: "11222333000181")

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "normalizes a masked cnpj down to its 14 digits before saving" do
      supplier = create(:supplier, cnpj: "11.222.333/0001-81")

      expect(supplier.cnpj).to eq("11222333000181")
    end

    it "considers a masked and an unmasked cnpj the same for uniqueness" do
      create(:supplier, cnpj: "11.222.333/0001-81")
      duplicate = build(:supplier, cnpj: "11222333000181")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:cnpj]).to be_present
    end

    it "accepts a real, checksum-valid cnpj" do
      supplier = build(:supplier, cnpj: "11444777000161")

      expect(supplier).to be_valid
    end

    it "rejects a cnpj with the wrong number of digits" do
      supplier = build(:supplier, cnpj: "1122233300018")

      expect(supplier).not_to be_valid
      expect(supplier.errors[:cnpj]).to be_present
    end

    it "rejects a cnpj with a well-formed but wrong check digit" do
      supplier = build(:supplier, cnpj: "11222333000180")

      expect(supplier).not_to be_valid
      expect(supplier.errors[:cnpj]).to be_present
    end

    it "rejects a repeated-digit placeholder even though its checksum is 0" do
      supplier = build(:supplier, cnpj: "11111111111111")

      expect(supplier).not_to be_valid
      expect(supplier.errors[:cnpj]).to be_present
    end
  end

  it "blocks deletion while a purchase still references it" do
    supplier = create(:supplier)
    create(:purchase, supplier: supplier)

    expect { supplier.destroy }.not_to change(Supplier, :count)
    expect(supplier.errors[:base]).to be_present
  end
end
