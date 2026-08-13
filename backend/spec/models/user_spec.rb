require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sector).optional }
    it { is_expected.to have_many(:stock_counts) }
    it { is_expected.to have_many(:user_sectors) }
    it { is_expected.to have_many(:sectors).through(:user_sectors) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  it "has no sector by default" do
    expect(create(:user).sector).to be_nil
  end

  describe "role" do
    it "defaults to operator" do
      expect(create(:user).role).to eq("operator")
    end

    it {
      is_expected.to define_enum_for(:role)
        .with_values(admin: "admin", manager: "manager", operator: "operator")
        .backed_by_column_of_type(:string)
    }

    it "rejects an unmapped role in Ruby before it ever reaches the database" do
      user = build(:user)

      expect { user.role = "superadmin" }.to raise_error(ArgumentError)
    end

    it "is enforced at the database level as defense in depth" do
      user = create(:user)

      expect {
        ActiveRecord::Base.connection.execute(
          "UPDATE users SET role = 'superadmin' WHERE id = #{user.id}"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /users_role_check/)
    end
  end

  describe "sector-based authorization (Bloco 6E)" do
    it "defaults all_sectors to false" do
      expect(create(:user).all_sectors).to be false
    end

    it "has no operable sectors when all_sectors is false and no sector is granted" do
      user = create(:user, all_sectors: false)

      expect(user.sector_ids).to eq([])
    end

    it "operates on exactly one sector when granted exactly one" do
      cozinha = create(:sector, name: "Cozinha")
      luiz = create(:user, name: "Luiz", role: "operator", all_sectors: false)
      create(:user_sector, user: luiz, sector: cozinha)

      expect(luiz.sector_ids).to contain_exactly(cozinha.id)
    end

    it "operates on every sector it was granted when granted more than one" do
      bar = create(:sector, name: "Bar")
      vinhos = create(:sector, name: "Vinhos")
      eric = create(:user, name: "Eric", role: "operator", all_sectors: false)
      create(:user_sector, user: eric, sector: bar)
      create(:user_sector, user: eric, sector: vinhos)

      expect(eric.sector_ids).to contain_exactly(bar.id, vinhos.id)
    end

    it "is unaffected by other users' sector grants" do
      cozinha = create(:sector, name: "Cozinha")
      confeitaria = create(:sector, name: "Confeitaria")
      luiz = create(:user, name: "Luiz", role: "operator")
      taris = create(:user, name: "Taris", role: "operator")
      create(:user_sector, user: luiz, sector: cozinha)
      create(:user_sector, user: taris, sector: confeitaria)

      expect(luiz.sector_ids).to contain_exactly(cozinha.id)
      expect(taris.sector_ids).to contain_exactly(confeitaria.id)
    end

    it "represents all_sectors=true without requiring a row per sector (e.g. Fran)" do
      create_list(:sector, 5)
      fran = create(:user, name: "Fran", role: "manager", all_sectors: true)

      expect(fran.all_sectors?).to be true
      expect(fran.user_sectors).to be_empty
    end

    it "an admin (e.g. Felipe) needs no sector grants — access is already unrestricted via the Ability" do
      felipe = create(:user, name: "Felipe", role: "admin")

      expect(felipe.admin?).to be true
      expect(felipe.user_sectors).to be_empty
    end

    describe "#has_all_sector_access?" do
      it "is true for an admin (Felipe), regardless of the all_sectors flag" do
        felipe = create(:user, name: "Felipe", role: "admin", all_sectors: true)

        expect(felipe.has_all_sector_access?).to be true
      end

      it "is true for a manager with all_sectors=true (Fran)" do
        fran = create(:user, name: "Fran", role: "manager", all_sectors: true)

        expect(fran.has_all_sector_access?).to be true
      end

      it "is false for an operator restricted to specific sectors (e.g. Luiz)" do
        cozinha = create(:sector, name: "Cozinha")
        luiz = create(:user, name: "Luiz", role: "operator", all_sectors: false)
        create(:user_sector, user: luiz, sector: cozinha)

        expect(luiz.has_all_sector_access?).to be false
      end

      it "is false for a user with neither the flag nor any sector grant" do
        user = create(:user, all_sectors: false)

        expect(user.has_all_sector_access?).to be false
      end
    end
  end

  describe "#active_for_authentication? (Bloco 6F)" do
    it "is true for an active user" do
      expect(create(:user, active: true).active_for_authentication?).to be true
    end

    it "is false for a deactivated user" do
      expect(create(:user, active: false).active_for_authentication?).to be false
    end
  end

  describe "must_leave_at_least_one_active_admin (Bloco 6F)" do
    it "blocks the sole active admin from changing their own role away from admin" do
      felipe = create(:user, name: "Felipe", role: "admin", active: true)

      felipe.role = "manager"

      expect(felipe).not_to be_valid
      expect(felipe.errors[:base]).to be_present
    end

    it "blocks the sole active admin from deactivating themselves" do
      felipe = create(:user, name: "Felipe", role: "admin", active: true)

      felipe.active = false

      expect(felipe).not_to be_valid
      expect(felipe.errors[:base]).to be_present
    end

    it "blocks demoting a different admin when they are the last one" do
      admin = create(:user, role: "admin", active: true)
      other_admin = create(:user, role: "admin", active: true)
      other_admin.update!(role: "operator") # no longer an admin, only `admin` remains

      admin.active = false

      expect(admin).not_to be_valid
    end

    it "allows changing role/active when another active admin still exists" do
      first_admin = create(:user, role: "admin", active: true)
      create(:user, role: "admin", active: true)

      first_admin.role = "manager"

      expect(first_admin).to be_valid
    end

    it "allows editing unrelated fields (name/email) of the sole active admin" do
      felipe = create(:user, name: "Felipe", role: "admin", active: true)

      felipe.name = "Felipe Editado"

      expect(felipe).to be_valid
    end

    it "allows deactivating a non-admin even when they are the only other user" do
      create(:user, role: "admin", active: true)
      operator = create(:user, role: "operator", active: true)

      operator.active = false

      expect(operator).to be_valid
    end
  end

  describe "jti (JWT revocation)" do
    it "gets a real value assigned automatically on create" do
      user = create(:user)

      expect(user.jti).to be_present
    end

    it "is unique per user" do
      first = create(:user)
      second = create(:user)

      expect(first.jti).not_to eq(second.jti)
    end

    it "rotates to a new value on revoke_jwt, invalidating every previously issued token" do
      user = create(:user)
      original_jti = user.jti

      User.revoke_jwt({}, user)

      expect(user.reload.jti).not_to eq(original_jti)
    end
  end
end
