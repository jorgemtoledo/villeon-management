require "rails_helper"

RSpec.describe Ability do
  describe "admin" do
    it "can manage everything, including Product" do
      ability = described_class.new(build(:user, role: "admin"))

      expect(ability.can?(:manage, :all)).to be true
      expect(ability.can?(:create, Product)).to be true
      expect(ability.can?(:update, Product.new)).to be true
    end
  end

  describe "manager" do
    it "has no general permission, but can read Product" do
      ability = described_class.new(build(:user, role: "manager"))

      expect(ability.can?(:manage, :all)).to be false
      expect(ability.can?(:index, Product)).to be true
      expect(ability.can?(:show, Product.new)).to be true
      expect(ability.can?(:create, Product)).to be false
      expect(ability.can?(:update, Product.new)).to be false
      expect(ability.can?(:activate, Product.new)).to be false
    end

    it "can create and update a Purchase, per the client's explicit rule (Felipe/Fran only)" do
      ability = described_class.new(build(:user, role: "manager"))

      expect(ability.can?(:create, Purchase)).to be true
      expect(ability.can?(:update, Purchase.new)).to be true
    end
  end

  describe "operator" do
    it "has no general permission, but can read Product" do
      ability = described_class.new(build(:user, role: "operator"))

      expect(ability.can?(:manage, :all)).to be false
      expect(ability.can?(:index, Product)).to be true
      expect(ability.can?(:show, Product.new)).to be true
      expect(ability.can?(:create, Product)).to be false
      expect(ability.can?(:update, Product.new)).to be false
      expect(ability.can?(:deactivate, Product.new)).to be false
    end

    it "cannot create or update a Purchase" do
      ability = described_class.new(build(:user, role: "operator"))

      expect(ability.can?(:create, Purchase)).to be false
      expect(ability.can?(:update, Purchase.new)).to be false
    end
  end

  describe "no user (unauthenticated)" do
    it "has no permission at all" do
      ability = described_class.new(nil)

      expect(ability.can?(:manage, :all)).to be false
      expect(ability.can?(:index, Product)).to be false
    end
  end

  describe "Estoque (ProductStock/StockCount) authorization" do
    let(:cozinha) { build_stubbed(:sector) }
    let(:bar) { build_stubbed(:sector) }

    it "admin can manage stock in any sector via manage :all" do
      ability = described_class.new(build(:user, role: "admin"))
      product = build_stubbed(:product, sector: bar)

      expect(ability.can?(:index, ProductStock)).to be true
      expect(ability.can?(:create, StockCount.new(product: product))).to be true
    end

    it "manager/operator with all_sectors=true can read/count stock in any sector" do
      %w[manager operator].each do |role|
        user = build(:user, role: role, all_sectors: true)
        ability = described_class.new(user)
        product = build_stubbed(:product, sector: bar)

        expect(ability.can?(:index, ProductStock)).to be true
        expect(ability.can?(:show, ProductStock.new(product: product))).to be true
        expect(ability.can?(:create, StockCount.new(product: product))).to be true
      end
    end

    it "a user restricted to specific sectors can only read/count stock there" do
      user = build_stubbed(:user, role: "operator", all_sectors: false)
      allow(user).to receive(:sector_ids).and_return([ cozinha.id ])
      ability = described_class.new(user)

      own_sector_stock = ProductStock.new(product: build_stubbed(:product, sector: cozinha))
      other_sector_stock = ProductStock.new(product: build_stubbed(:product, sector: bar))

      expect(ability.can?(:show, own_sector_stock)).to be true
      expect(ability.can?(:show, other_sector_stock)).to be false
    end

    it "a user with no sector at all and all_sectors=false has no stock permission" do
      user = build_stubbed(:user, role: "operator", all_sectors: false)
      allow(user).to receive(:sector_ids).and_return([])
      ability = described_class.new(user)

      expect(ability.can?(:index, ProductStock)).to be false
      expect(ability.can?(:create, StockCount.new(product: build_stubbed(:product)))).to be false
    end
  end

  describe "priority/needs_advance_order authorization (Bloco 6G Parte 4)" do
    let(:cozinha) { build_stubbed(:sector) }
    let(:bar) { build_stubbed(:sector) }

    it "manager gets it unconditionally, in any sector, even without all_sectors" do
      user = build(:user, role: "manager", all_sectors: false)
      ability = described_class.new(user)

      expect(ability.can?(:update_priority, ProductStock.new(product: build_stubbed(:product, sector: bar)))).to be true
    end

    it "a sector-restricted operator gets it only within their own sector" do
      user = build_stubbed(:user, role: "operator", all_sectors: false)
      allow(user).to receive(:sector_ids).and_return([ cozinha.id ])
      ability = described_class.new(user)

      own_sector_stock = ProductStock.new(product: build_stubbed(:product, sector: cozinha))
      other_sector_stock = ProductStock.new(product: build_stubbed(:product, sector: bar))

      expect(ability.can?(:update_priority, own_sector_stock)).to be true
      expect(ability.can?(:update_priority, other_sector_stock)).to be false
    end

    it "a user with no sector at all and all_sectors=false has no permission" do
      user = build_stubbed(:user, role: "operator", all_sectors: false)
      allow(user).to receive(:sector_ids).and_return([])
      ability = described_class.new(user)

      expect(ability.can?(:update_priority, ProductStock.new(product: build_stubbed(:product)))).to be false
    end
  end
end
