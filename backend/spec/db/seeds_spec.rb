require "rails_helper"

RSpec.describe "db/seeds.rb" do
  subject(:run_seeds) { load Rails.root.join("db/seeds.rb") }

  it "creates the 5 real sectors from the client's spreadsheet" do
    run_seeds

    expect(Sector.pluck(:name)).to match_array(%w[Cozinha Confeitaria Bar Vinhos Limpeza])
  end

  it "creates the 33 real units from the client's spreadsheet" do
    run_seeds

    expect(Unit.count).to eq(33)
  end

  it "does not create Category or Subcategory records, since there is no reliable source data yet" do
    run_seeds

    expect(Category.count).to eq(0)
    expect(Subcategory.count).to eq(0)
  end

  it "does not create duplicates when run more than once" do
    run_seeds
    run_seeds
    run_seeds

    expect(Sector.count).to eq(5)
    expect(Unit.count).to eq(33)
  end

  it "does not raise when records already exist" do
    run_seeds

    expect { run_seeds }.not_to raise_error
  end

  it "keeps distinct unit spellings as separate rows instead of merging them" do
    run_seeds

    expect(Unit.where(abbreviation: %w[un unid unidade]).count).to eq(3)
  end
end
