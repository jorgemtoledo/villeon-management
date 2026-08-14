require "rails_helper"

RSpec.describe Importers::ProductSubcategoryImporter do
  def valid_row(row_number: 2, product_code: "COZ-001", subcategory_code: "PRO")
    { row_number: row_number, product_code: product_code, subcategory_code: subcategory_code }
  end

  def importer_with_rows(rows, dry_run: false)
    importer = described_class.new("irrelevant.xlsx", dry_run: dry_run)
    allow(importer).to receive(:read_rows).and_return(rows)
    importer
  end

  describe "linking a product to a subcategory" do
    it "creates the Subcategory (code only, name = code) and links the product" do
      product = create(:product, code: "COZ-001")

      report = importer_with_rows([ valid_row ]).call

      expect(report.subcategories_created).to eq(1)
      expect(report.linked).to eq(1)
      subcategory = Subcategory.find_by(code: "PRO")
      expect(subcategory.name).to eq("PRO")
      expect(product.reload.subcategory).to eq(subcategory)
    end

    it "reuses the same Subcategory for several products with the same code, never duplicating it" do
      create(:product, code: "COZ-001")
      create(:product, code: "COZ-002")

      report = importer_with_rows([
        valid_row(product_code: "COZ-001", subcategory_code: "PRO"),
        valid_row(row_number: 3, product_code: "COZ-002", subcategory_code: "PRO")
      ]).call

      expect(report.subcategories_created).to eq(1)
      expect(Subcategory.where(code: "PRO").count).to eq(1)
      expect(report.linked).to eq(2)
    end

    it "is idempotent — running again reports unchanged, doesn't duplicate the Subcategory or re-link" do
      create(:product, code: "COZ-001")
      importer_with_rows([ valid_row ]).call

      report = importer_with_rows([ valid_row ]).call

      expect(report.linked).to eq(0)
      expect(report.unchanged).to eq(1)
      expect(report.subcategories_created).to eq(0)
      expect(Subcategory.count).to eq(1)
    end

    it "never modifies the code — stores exactly what the spreadsheet has, no interpretation" do
      create(:product, code: "COZ-001")

      importer_with_rows([ valid_row(subcategory_code: "ACU") ]).call

      expect(Subcategory.pluck(:code)).to eq([ "ACU" ])
    end
  end

  describe "products without a subcategory in the spreadsheet" do
    it "leaves subcategory_id nil and does not invent one" do
      product = create(:product, code: "COZ-001")

      report = importer_with_rows([ valid_row(subcategory_code: "") ]).call

      expect(report.without_subcategory).to eq(1)
      expect(report.linked).to eq(0)
      expect(product.reload.subcategory_id).to be_nil
      expect(Subcategory.count).to eq(0)
    end
  end

  describe "invalid rows" do
    it "flags a product that doesn't exist, without creating a Subcategory for it" do
      report = importer_with_rows([ valid_row(product_code: "GHOST-1") ]).call

      expect(report.invalid.size).to eq(1)
      expect(report.invalid.first.message).to match(/não encontrado/)
      expect(Subcategory.count).to eq(0)
    end

    it "does not abort the whole import because of one invalid row" do
      create(:product, code: "COZ-001")

      report = importer_with_rows([
        valid_row(row_number: 2, product_code: "GHOST-1"),
        valid_row(row_number: 3, product_code: "COZ-001")
      ]).call

      expect(report.invalid.size).to eq(1)
      expect(report.linked).to eq(1)
    end
  end

  describe "DRY_RUN" do
    it "does not persist anything, but still reports accurate counts" do
      create(:product, code: "COZ-001")

      report = importer_with_rows([ valid_row ], dry_run: true).call

      expect(report.dry_run).to be true
      expect(report.subcategories_created).to eq(1)
      expect(report.linked).to eq(1)
      expect(Subcategory.count).to eq(0)
      expect(Product.find_by(code: "COZ-001").subcategory_id).to be_nil
    end
  end
end
