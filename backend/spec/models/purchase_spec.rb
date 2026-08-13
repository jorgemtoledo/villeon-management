require "rails_helper"

RSpec.describe Purchase, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:supplier) }
    it { is_expected.to have_many(:purchase_items) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:purchased_at) }
    it { is_expected.to validate_presence_of(:total_amount) }
    it { is_expected.to validate_numericality_of(:total_amount).is_greater_than_or_equal_to(0) }
  end

  it "does not require a unique invoice_number, since the client's history already has apparent duplicates" do
    create(:purchase, invoice_number: "NF-001")
    other = build(:purchase, invoice_number: "NF-001")

    expect(other).to be_valid
  end

  it "is enforced at the database level for non-negative total_amount" do
    purchase = create(:purchase)

    expect {
      purchase.update_column(:total_amount, -1)
    }.to raise_error(ActiveRecord::StatementInvalid, /purchases_total_amount_check/)
  end

  it "blocks deletion while a purchase_item still references it" do
    purchase = create(:purchase)
    create(:purchase_item, purchase: purchase)

    expect { purchase.destroy }.not_to change(Purchase, :count)
    expect(purchase.errors[:base]).to be_present
  end
end
