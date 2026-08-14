require "rails_helper"

RSpec.describe StockAuditEntry, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { create(:stock_audit_entry) }

    it { is_expected.to validate_presence_of(:field) }
    it { is_expected.to validate_inclusion_of(:field).in_array(%w[current_quantity priority needs_advance_order]) }
  end

  describe "immutability" do
    it "cannot be updated once created" do
      entry = create(:stock_audit_entry)

      expect { entry.update(new_value: "999") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "cannot be destroyed" do
      entry = create(:stock_audit_entry)

      expect { entry.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(StockAuditEntry.exists?(entry.id)).to be true
    end
  end
end
