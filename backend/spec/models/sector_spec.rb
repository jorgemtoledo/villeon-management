require "rails_helper"

RSpec.describe Sector, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:products) }
    it { is_expected.to have_many(:user_sectors) }
  end

  describe "validations" do
    subject { create(:sector) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  it "blocks deletion while a product still references it" do
    sector = create(:sector)
    create(:product, sector: sector)

    expect { sector.destroy }.not_to change(Sector, :count)
    expect(sector.errors[:base]).to be_present
  end

  it "removes user_sectors grants (not blocked by them) when the sector is destroyed" do
    sector = create(:sector)
    user_sector = create(:user_sector, sector: sector)

    expect { sector.destroy }.to change(Sector, :count).by(-1)
    expect(UserSector.exists?(user_sector.id)).to be false
  end
end
