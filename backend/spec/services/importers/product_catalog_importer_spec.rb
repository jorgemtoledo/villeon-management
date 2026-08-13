require "rails_helper"

RSpec.describe Importers::ProductCatalogImporter do
  let!(:sector) { create(:sector, name: "Cozinha") }
  let!(:unit_kg) { create(:unit, abbreviation: "kg", name: "Quilograma") }

  def valid_row(row_number: 2, code: "COZ-001", name: "Produto Teste", sector_name: "Cozinha",
                purchase_unit_abbr: "kg", stock_unit_abbr: "kg", conversion_factor_raw: 1,
                observations: "")
    {
      row_number: row_number,
      code: code,
      name: name,
      sector_name: sector_name,
      purchase_unit_abbr: purchase_unit_abbr,
      stock_unit_abbr: stock_unit_abbr,
      conversion_factor_raw: conversion_factor_raw,
      observations: observations
    }
  end

  def importer_with_rows(rows, dry_run: false)
    importer = described_class.new("irrelevant.xlsx", dry_run: dry_run)
    allow(importer).to receive(:read_rows).and_return(rows)
    importer
  end

  describe "creating and updating" do
    it "creates a new product from a valid row" do
      report = importer_with_rows([ valid_row ]).call

      expect(report.created).to eq(1)
      expect(report.invalid).to be_empty
      product = Product.find_by(code: "COZ-001")
      expect(product.name).to eq("Produto Teste")
      expect(product.sector).to eq(sector)
      expect(product.purchase_unit).to eq(unit_kg)
      expect(product.stock_unit).to eq(unit_kg)
    end

    it "is idempotent — running again with the same data reports unchanged, not a duplicate" do
      importer_with_rows([ valid_row ]).call
      report = importer_with_rows([ valid_row ]).call

      expect(report.created).to eq(0)
      expect(report.unchanged).to eq(1)
      expect(Product.count).to eq(1)
    end

    it "reports updated when an existing product's data actually changes" do
      importer_with_rows([ valid_row(name: "Nome 1") ]).call
      report = importer_with_rows([ valid_row(name: "Nome 2") ]).call

      expect(report.updated).to eq(1)
      expect(report.created).to eq(0)
      expect(Product.find_by(code: "COZ-001").name).to eq("Nome 2")
    end
  end

  describe "DRY_RUN" do
    it "does not persist anything, but still reports accurate counts" do
      report = importer_with_rows([ valid_row ], dry_run: true).call

      expect(report.dry_run).to be true
      expect(report.created).to eq(1)
      expect(Product.count).to eq(0)
    end
  end

  describe "conversion_factor (Rendimento)" do
    it "uses the given value when present and positive" do
      report = importer_with_rows([ valid_row(conversion_factor_raw: 2.5) ]).call

      expect(report.created).to eq(1)
      expect(report.warnings).to be_empty
      expect(Product.find_by(code: "COZ-001").conversion_factor).to eq(BigDecimal("2.5"))
    end

    it "defaults to 1 and records a warning when blank" do
      report = importer_with_rows([ valid_row(conversion_factor_raw: nil) ]).call

      expect(report.created).to eq(1)
      expect(report.warnings.size).to eq(1)
      expect(report.warnings.first.message).to match(/Rendimento vazio/)
      expect(Product.find_by(code: "COZ-001").conversion_factor).to eq(1)
    end

    it "marks the row invalid when the value isn't numeric" do
      report = importer_with_rows([ valid_row(conversion_factor_raw: "abc") ]).call

      expect(report.created).to eq(0)
      expect(report.invalid.size).to eq(1)
      expect(Product.exists?(code: "COZ-001")).to be false
    end

    it "marks the row invalid when the value is zero or negative" do
      report = importer_with_rows([ valid_row(conversion_factor_raw: 0) ]).call

      expect(report.invalid.size).to eq(1)
      expect(Product.exists?(code: "COZ-001")).to be false
    end
  end

  describe "colibri_code" do
    it "extracts the numeric code from free-text observations" do
      importer_with_rows([ valid_row(observations: "Cód. Colibri: 65") ]).call

      expect(Product.find_by(code: "COZ-001").colibri_code).to eq("65")
    end

    it "extracts the code even with extra trailing notes" do
      importer_with_rows([ valid_row(observations: "Cód. Colibri: 42 · caixa c/ 24") ]).call

      expect(Product.find_by(code: "COZ-001").colibri_code).to eq("42")
    end

    it "leaves colibri_code nil when there's no match, without treating it as an error" do
      report = importer_with_rows([ valid_row(observations: "sem nenhum código aqui") ]).call

      expect(report.invalid).to be_empty
      expect(Product.find_by(code: "COZ-001").colibri_code).to be_nil
    end

    it "flags a colibri_code shared by two different products, without blocking either" do
      rows = [
        valid_row(code: "COZ-001", observations: "Cód. Colibri: 65"),
        valid_row(code: "COZ-002", observations: "Cód. Colibri: 65")
      ]

      report = importer_with_rows(rows).call

      expect(report.created).to eq(2)
      expect(report.duplicate_colibri_codes).to eq({ "65" => %w[COZ-001 COZ-002] })
    end
  end

  describe "invalid rows" do
    it "flags a missing code" do
      report = importer_with_rows([ valid_row(code: "") ]).call

      expect(report.invalid.size).to eq(1)
      expect(report.invalid.first.message).to match(/Código ausente/)
    end

    it "flags a missing name" do
      report = importer_with_rows([ valid_row(name: "") ]).call

      expect(report.invalid.first.message).to match(/nome.*ausente/i)
    end

    it "flags an unknown sector without creating one" do
      report = importer_with_rows([ valid_row(sector_name: "Setor Inexistente") ]).call

      expect(report.invalid.size).to eq(1)
      expect(Sector.exists?(name: "Setor Inexistente")).to be false
    end

    it "flags an unknown unit without creating one" do
      report = importer_with_rows([ valid_row(purchase_unit_abbr: "unidade-fake") ]).call

      expect(report.invalid.size).to eq(1)
      expect(Unit.exists?(abbreviation: "unidade-fake")).to be false
    end

    it "flags a duplicate code within the same file, keeping only the first occurrence" do
      rows = [
        valid_row(row_number: 2, code: "COZ-001", name: "Primeiro"),
        valid_row(row_number: 3, code: "COZ-001", name: "Segundo")
      ]

      report = importer_with_rows(rows).call

      expect(report.created).to eq(1)
      expect(report.invalid.size).to eq(1)
      expect(report.invalid.first.message).to match(/duplicado/)
      expect(Product.find_by(code: "COZ-001").name).to eq("Primeiro")
    end

    it "does not abort the whole import because of one invalid row" do
      rows = [
        valid_row(row_number: 2, code: "COZ-001"),
        valid_row(row_number: 3, code: ""),
        valid_row(row_number: 4, code: "COZ-003")
      ]

      report = importer_with_rows(rows).call

      expect(report.created).to eq(2)
      expect(report.invalid.size).to eq(1)
    end
  end

  describe "unexpected errors" do
    it "rolls back everything already written in the same run (no partial writes)" do
      rows = [
        valid_row(row_number: 2, code: "COZ-001"),
        valid_row(row_number: 3, code: "COZ-002"),
        valid_row(row_number: 4, code: "COZ-003")
      ]
      importer = importer_with_rows(rows)

      call_count = 0
      allow(Product).to receive(:find_or_initialize_by).and_wrap_original do |original, *args|
        call_count += 1
        raise "boom" if call_count == 2

        original.call(*args)
      end

      expect { importer.call }.to raise_error("boom")
      expect(Product.count).to eq(0)
    end
  end
end
