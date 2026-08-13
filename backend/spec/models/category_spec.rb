require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:subcategories) }
    it { is_expected.to have_many(:products) }
  end

  describe "validations" do
    subject { create(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  it "blocks deletion while a subcategory still references it" do
    category = create(:category)
    create(:subcategory, category: category)

    expect { category.destroy }.not_to change(Category, :count)
    expect(category.errors[:base]).to be_present
  end
end
