require "rails_helper"

RSpec.describe Subcategory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to have_many(:products) }
  end

  describe "validations" do
    subject { create(:subcategory) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end

  it "allows a subcategory with no category — the spreadsheet's Subcategoria codes (Bloco Subcategoria) are a flat list, not nested under Category" do
    subcategory = build(:subcategory, category: nil)

    expect(subcategory).to be_valid
  end

  it "allows a nil description while the code mapping is still unconfirmed" do
    subcategory = build(:subcategory, name: nil)

    expect(subcategory).to be_valid
  end
end
