require "rails_helper"

RSpec.describe Unit, type: :model do
  describe "validations" do
    subject { create(:unit) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_uniqueness_of(:abbreviation) }
  end

  it "blocks deletion while a product still references it as purchase_unit" do
    unit = create(:unit)
    create(:product, purchase_unit: unit)

    expect { unit.destroy }.not_to change(Unit, :count)
    expect(unit.errors[:base]).to be_present
  end

  it "blocks deletion while a product still references it as stock_unit" do
    unit = create(:unit)
    create(:product, stock_unit: unit)

    expect { unit.destroy }.not_to change(Unit, :count)
    expect(unit.errors[:base]).to be_present
  end
end
