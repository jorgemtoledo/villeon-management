require "rails_helper"

RSpec.describe Importers::PurchaseHistoryImporter do
  let!(:supplier) { create(:supplier, name: "Isar Alimentos") }
  let!(:product_a) { create(:product, code: "COZ-011", name: "Agrião") }
  let!(:product_b) { create(:product, code: "COZ-043", name: "Salsinha") }

  def valid_row(row_number: 2, date_raw: "2026-01-02", code: "COZ-011", supplier_raw: "Isar Alimentos",
                quantity_raw: 2.0, unit_price_raw: 3.5, total_raw: 7.0)
    { row_number: row_number, date_raw: date_raw, code: code, supplier_raw: supplier_raw,
      quantity_raw: quantity_raw, unit_price_raw: unit_price_raw, total_raw: total_raw }
  end

  def importer_with_rows(rows, dry_run: false)
    importer = described_class.new("irrelevant.xlsx", dry_run: dry_run)
    allow(importer).to receive(:read_rows).and_return(rows)
    importer
  end

  describe "creating purchases and items" do
    it "creates one Purchase with one PurchaseItem from a single valid row" do
      report = importer_with_rows([ valid_row ]).call

      expect(report.purchases_created).to eq(1)
      expect(report.items_created).to eq(1)
      expect(Purchase.count).to eq(1)
      purchase = Purchase.first
      expect(purchase.supplier).to eq(supplier)
      expect(purchase.purchased_at.to_date).to eq(Date.new(2026, 1, 2))
      expect(purchase.purchase_items.sole.product).to eq(product_a)
      expect(purchase.purchase_items.sole.quantity).to eq(2)
      expect(purchase.purchase_items.sole.unit_price).to eq(3.5)
    end

    it "groups multiple rows with the same supplier and date into a single Purchase" do
      rows = [
        valid_row(row_number: 2, code: "COZ-011", quantity_raw: 2.0, unit_price_raw: 3.5),
        valid_row(row_number: 3, code: "COZ-043", quantity_raw: 6.0, unit_price_raw: 2.5)
      ]

      report = importer_with_rows(rows).call

      expect(report.purchases_created).to eq(1)
      expect(report.items_created).to eq(2)
      expect(Purchase.count).to eq(1)
      expect(Purchase.first.purchase_items.count).to eq(2)
    end

    it "creates separate Purchases for different dates or different suppliers" do
      other_supplier = create(:supplier, name: "Outro Fornecedor")
      rows = [
        valid_row(row_number: 2, date_raw: "2026-01-02"),
        valid_row(row_number: 3, date_raw: "2026-01-03"),
        valid_row(row_number: 4, date_raw: "2026-01-02", supplier_raw: "Outro Fornecedor")
      ]

      report = importer_with_rows(rows).call

      expect(report.purchases_created).to eq(3)
      expect(Purchase.count).to eq(3)
    end

    it "computes Purchase.total_amount from quantity × unit_price, never trusting the spreadsheet's Total column" do
      row = valid_row(quantity_raw: 2.0, unit_price_raw: 3.5, total_raw: 999_999.0)

      importer_with_rows([ row ]).call

      expect(Purchase.first.total_amount).to eq(BigDecimal("7.0"))
    end

    it "computes total_amount from the precision actually stored in unit_price, not the spreadsheet's raw value" do
      # Regression case found in the real Histórico (Multiáguas, 2026-01-12):
      # the sheet carries unit_price with 6 decimals; purchase_items.unit_price
      # only stores 4. Using the raw 6-decimal value for total_amount gives
      # 616.00 (168 × 3.666667 = 616.000056), while PurchaseItem itself computes
      # total_price from the persisted, already-rounded 3.6667 (168 × 3.6667 =
      # 616.0056 → 616.01). total_amount must match the latter, not the former.
      row = valid_row(quantity_raw: 168.0, unit_price_raw: 3.666667, total_raw: 616.000056)

      importer_with_rows([ row ]).call

      item = PurchaseItem.sole
      expect(item.unit_price).to eq(BigDecimal("3.6667"))
      expect(item.total_price).to eq(BigDecimal("616.01"))
      expect(Purchase.first.total_amount).to eq(BigDecimal("616.01"))
    end

    it "keeps Purchase.total_amount exactly equal to SUM(PurchaseItem.total_price) across every purchase" do
      rows = [
        valid_row(row_number: 2, code: "COZ-011", quantity_raw: 168.0, unit_price_raw: 3.666667),
        valid_row(row_number: 3, code: "COZ-043", date_raw: "2026-01-03", quantity_raw: 3.0, unit_price_raw: 2.111111)
      ]

      importer_with_rows(rows).call

      Purchase.find_each do |purchase|
        expect(purchase.total_amount).to eq(purchase.purchase_items.sum(:total_price))
      end
    end

    it "preserves exact duplicate rows as two separate PurchaseItems — never deduplicates" do
      rows = [ valid_row(row_number: 2), valid_row(row_number: 9) ]

      report = importer_with_rows(rows).call

      expect(Purchase.first.purchase_items.count).to eq(2)
      expect(report.duplicate_groups.size).to eq(1)
      expect(report.duplicate_groups.first.map { |r| r[:row_number] }).to contain_exactly(2, 9)
    end
  end

  describe "idempotency" do
    it "does not duplicate the Purchase on a second run — same id, items resynced" do
      importer_with_rows([ valid_row ]).call
      purchase_id = Purchase.first.id

      report = importer_with_rows([ valid_row ]).call

      expect(report.purchases_created).to eq(0)
      expect(report.purchases_updated).to eq(1)
      expect(Purchase.count).to eq(1)
      expect(Purchase.first.id).to eq(purchase_id)
    end

    it "actually destroys and rebuilds items on resync (item ids change), keeping the count stable" do
      importer_with_rows([ valid_row ]).call
      old_item_id = PurchaseItem.first.id

      importer_with_rows([ valid_row ]).call

      expect(PurchaseItem.count).to eq(1)
      expect(PurchaseItem.first.id).not_to eq(old_item_id)
    end

    it "running the same import twice in a row produces the same final state" do
      rows = [
        valid_row(row_number: 2, code: "COZ-011", quantity_raw: 2.0, unit_price_raw: 3.5),
        valid_row(row_number: 3, code: "COZ-043", quantity_raw: 6.0, unit_price_raw: 2.5)
      ]

      importer_with_rows(rows).call
      importer_with_rows(rows).call

      expect(Purchase.count).to eq(1)
      expect(PurchaseItem.count).to eq(2)
      expect(Purchase.first.total_amount).to eq(BigDecimal("7.0") + BigDecimal("15.0"))
    end

    it "reflects a changed spreadsheet on the next run without touching the Purchase id" do
      importer_with_rows([ valid_row(row_number: 2, code: "COZ-011") ]).call
      purchase_id = Purchase.first.id

      importer_with_rows([
        valid_row(row_number: 2, code: "COZ-011"),
        valid_row(row_number: 3, code: "COZ-043")
      ]).call

      expect(Purchase.count).to eq(1)
      expect(Purchase.first.id).to eq(purchase_id)
      expect(Purchase.first.purchase_items.count).to eq(2)
    end
  end

  describe "DRY_RUN" do
    it "does not persist anything, but still reports accurate counts" do
      report = importer_with_rows([ valid_row ], dry_run: true).call

      expect(report.dry_run).to be true
      expect(report.purchases_created).to eq(1)
      expect(Purchase.count).to eq(0)
      expect(PurchaseItem.count).to eq(0)
    end
  end

  describe "fornecedor resolution" do
    it "resolves via the approved alias map, without creating a new Supplier" do
      row = valid_row(supplier_raw: "Isar")

      report = importer_with_rows([ row ]).call

      expect(report.purchases_created).to eq(1)
      expect(Purchase.first.supplier).to eq(supplier)
      expect(Supplier.count).to eq(1)
    end

    it "marks the row invalid and does not create a Supplier when the fornecedor can't be resolved" do
      row = valid_row(supplier_raw: "Fornecedor Totalmente Desconhecido")

      report = importer_with_rows([ row ]).call

      expect(report.purchases_created).to eq(0)
      expect(report.unresolved_suppliers.size).to eq(1)
      expect(report.unresolved_suppliers.first.row).to eq(2)
      expect(Supplier.count).to eq(1)
      expect(Purchase.count).to eq(0)
    end
  end

  describe "produto resolution" do
    it "resolves exclusively by Product.code" do
      report = importer_with_rows([ valid_row(code: "COZ-043") ]).call

      expect(Purchase.first.purchase_items.sole.product).to eq(product_b)
      expect(report.unresolved_products).to be_empty
    end

    it "marks the row invalid and does not create a Product when the code can't be resolved" do
      row = valid_row(code: "INEXISTENTE-999")

      report = importer_with_rows([ row ]).call

      expect(report.purchases_created).to eq(0)
      expect(report.unresolved_products.size).to eq(1)
      expect(Product.exists?(code: "INEXISTENTE-999")).to be false
    end
  end

  describe "invalid rows don't abort the batch" do
    it "imports the valid rows even when other rows in the same run are invalid" do
      rows = [
        valid_row(row_number: 2, code: "COZ-011"),
        valid_row(row_number: 3, supplier_raw: "Desconhecido"),
        valid_row(row_number: 4, code: "SEM-CODIGO"),
        valid_row(row_number: 5, date_raw: "não é uma data")
      ]

      report = importer_with_rows(rows).call

      expect(report.purchases_created).to eq(1)
      expect(report.invalid.size).to eq(3)
    end

    it "excludes only the invalid row from a group, keeping the rest of that purchase" do
      rows = [
        valid_row(row_number: 2, code: "COZ-011"),
        valid_row(row_number: 3, code: "COZ-043", quantity_raw: -1)
      ]

      report = importer_with_rows(rows).call

      expect(Purchase.first.purchase_items.count).to eq(1)
      expect(report.invalid.size).to eq(1)
    end
  end

  describe "#to_s" do
    it "documents the supplier+date approximation limitation is exercised via grouping, and reports total value" do
      report = importer_with_rows([ valid_row ]).call

      expect(report.to_s).to include("Purchases criados: 1")
      expect(report.to_s).to include("Valor total importado: R$ 7.00")
    end
  end
end
