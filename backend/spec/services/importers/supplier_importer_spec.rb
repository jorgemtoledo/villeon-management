require "rails_helper"

RSpec.describe Importers::SupplierImporter do
  def valid_row(row_number: 2, name: "Distribuidora ABC", cnpj_root_candidate: nil)
    { row_number: row_number, name: name, cnpj_root_candidate: cnpj_root_candidate }
  end

  def importer_with_rows(rows, dry_run: false)
    importer = described_class.new("irrelevant.xlsx", dry_run: dry_run)
    allow(importer).to receive(:read_rows).and_return(rows)
    importer
  end

  describe "creating and updating" do
    it "creates a new supplier from a valid row, with no cnpj and active true" do
      report = importer_with_rows([ valid_row(name: "Distribuidora ABC") ]).call

      expect(report.created).to eq(1)
      expect(report.invalid).to be_empty
      supplier = Supplier.find_by(name: "Distribuidora ABC")
      expect(supplier.cnpj).to be_nil
      expect(supplier.active).to be true
    end

    it "is idempotent — running again with the same name reports unchanged, not a duplicate" do
      importer_with_rows([ valid_row(name: "Distribuidora ABC") ]).call
      report = importer_with_rows([ valid_row(name: "Distribuidora ABC") ]).call

      expect(report.created).to eq(0)
      expect(report.unchanged).to eq(1)
      expect(Supplier.count).to eq(1)
    end

    it "matches an existing supplier by normalized name despite a casing difference, and syncs the display name" do
      create(:supplier, name: "Distribuidora ABC")

      report = importer_with_rows([ valid_row(name: "DISTRIBUIDORA ABC") ]).call

      expect(report.created).to eq(0)
      expect(report.updated).to eq(1)
      expect(Supplier.count).to eq(1)
      expect(Supplier.first.name).to eq("DISTRIBUIDORA ABC")
    end

    it "documents the name-based-idempotency limitation: renaming creates a new record, not an update" do
      # Real CNPJ isn't available yet (see class comment) — the match key is
      # the normalized name, so a genuine rename is indistinguishable from a
      # brand new supplier. This is expected, not a bug, until real CNPJs
      # let reconciliation switch to a stable key.
      importer_with_rows([ valid_row(name: "Nome 1") ]).call
      report = importer_with_rows([ valid_row(name: "Nome 2") ]).call

      expect(report.created).to eq(1)
      expect(Supplier.count).to eq(2)
    end

    it "never overwrites cnpj or active on an existing supplier — the importer only manages name" do
      supplier = create(:supplier, name: "Distribuidora ABC", cnpj: "11222333000181", active: false)

      importer_with_rows([ valid_row(name: "Distribuidora ABC") ]).call

      expect(supplier.reload.cnpj).to eq("11222333000181")
      expect(supplier.active).to be false
    end
  end

  describe "duplicate names within the spreadsheet" do
    it "flags the second occurrence and only persists the first" do
      report = importer_with_rows([
        valid_row(row_number: 2, name: "Distribuidora ABC"),
        valid_row(row_number: 5, name: "distribuidora abc")
      ]).call

      expect(report.created).to eq(1)
      expect(report.duplicate_names.size).to eq(1)
      expect(report.duplicate_names.first.row).to eq(5)
      expect(report.duplicate_names.first.message).to match(/linha 2/)
      expect(Supplier.count).to eq(1)
    end
  end

  describe "invalid rows" do
    it "marks a blank name as invalid without aborting the batch" do
      report = importer_with_rows([
        valid_row(row_number: 2, name: ""),
        valid_row(row_number: 3, name: "Distribuidora ABC")
      ]).call

      expect(report.invalid.size).to eq(1)
      expect(report.created).to eq(1)
      expect(Supplier.count).to eq(1)
    end
  end

  describe "DRY_RUN" do
    it "does not persist anything, but still reports accurate counts" do
      report = importer_with_rows([ valid_row ], dry_run: true).call

      expect(report.dry_run).to be true
      expect(report.created).to eq(1)
      expect(Supplier.count).to eq(0)
    end
  end

  describe "cnpj root candidates (report-only, never persisted)" do
    it "lists rows that had a De-Para match, without touching Supplier#cnpj" do
      report = importer_with_rows([
        valid_row(name: "Com candidato", cnpj_root_candidate: "12345678"),
        valid_row(row_number: 3, name: "Sem candidato", cnpj_root_candidate: nil)
      ]).call

      expect(report.cnpj_root_candidates.size).to eq(1)
      expect(report.cnpj_root_candidates.first.name).to eq("Com candidato")
      expect(report.cnpj_root_candidates.first.cnpj_root).to eq("12345678")
      expect(Supplier.find_by(name: "Com candidato").cnpj).to be_nil
    end
  end

  describe "#to_s" do
    it "includes the explicit name-based-idempotency limitation note" do
      report = importer_with_rows([ valid_row ]).call

      expect(report.to_s).to match(/nenhum fornecedor tem CNPJ completo válido/i)
    end
  end
end
