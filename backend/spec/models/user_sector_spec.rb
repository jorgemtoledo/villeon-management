require "rails_helper"

RSpec.describe UserSector, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:sector) }
  end

  describe "validations" do
    it "allows the same sector to be granted to different users" do
      sector = create(:sector)
      create(:user_sector, sector: sector)

      expect(build(:user_sector, sector: sector)).to be_valid
    end

    it "allows the same user to be granted different sectors" do
      user = create(:user)
      create(:user_sector, user: user)

      expect(build(:user_sector, user: user)).to be_valid
    end

    it "rejects granting the same sector to the same user twice" do
      user = create(:user)
      sector = create(:sector)
      create(:user_sector, user: user, sector: sector)

      duplicate = build(:user_sector, user: user, sector: sector)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sector_id]).to be_present
    end

    it "is enforced at the database level as defense in depth" do
      user = create(:user)
      sector = create(:sector)
      create(:user_sector, user: user, sector: sector)

      expect {
        ActiveRecord::Base.connection.execute(
          "INSERT INTO user_sectors (user_id, sector_id, created_at, updated_at) " \
          "VALUES (#{user.id}, #{sector.id}, NOW(), NOW())"
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  it "is destroyed when the user is destroyed" do
    user_sector = create(:user_sector)
    user = user_sector.user

    user.destroy

    expect(UserSector.exists?(user_sector.id)).to be false
  end

  it "is destroyed when the sector is destroyed" do
    user_sector = create(:user_sector)
    sector = user_sector.sector

    sector.destroy

    expect(UserSector.exists?(user_sector.id)).to be false
  end
end
