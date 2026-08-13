require "rails_helper"

RSpec.describe Subcategory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:products) }
  end

  describe "validations" do
    subject { create(:subcategory) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(:category_id) }
  end

  it "allows the same code under a different category" do
    code = "14"
    create(:subcategory, code: code)

    other = build(:subcategory, code: code)

    expect(other).to be_valid
  end

  it "allows a nil description while the code mapping is still unconfirmed" do
    subcategory = build(:subcategory, name: nil)

    expect(subcategory).to be_valid
  end
end
