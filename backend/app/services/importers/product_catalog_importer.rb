module Importers
  # Imports Product rows from the "Catálogo Mestre" sheet of the client's
  # MAPA COMPRAS.xlsx spreadsheet. Read-only against the source file; the
  # only writes are to Product, keyed by `code` (idempotent: re-running
  # updates existing rows instead of duplicating them).
  #
  # Out of scope for this importer (Bloco 5A): suppliers, purchase history,
  # fichas técnicas, stock levels, category/subcategory, Colibri.
  class ProductCatalogImporter
    SHEET_NAME = "Catálogo Mestre".freeze
    COLIBRI_CODE_PATTERN = /C[óo]d\.?\s*Colibri:?\s*(\d+)/i

    RowIssue = Struct.new(:row, :code, :message, keyword_init: true)

    class Report
      attr_reader :total_rows, :created, :updated, :unchanged, :invalid, :warnings,
                  :duplicate_colibri_codes, :dry_run

      def initialize(total_rows:, created:, updated:, unchanged:, invalid:, warnings:,
                      duplicate_colibri_codes:, dry_run:)
        @total_rows = total_rows
        @created = created
        @updated = updated
        @unchanged = unchanged
        @invalid = invalid
        @warnings = warnings
        @duplicate_colibri_codes = duplicate_colibri_codes
        @dry_run = dry_run
      end

      def to_s
        lines = summary_lines
        append_issues(lines, "Linhas inválidas", invalid)
        append_issues(lines, "Avisos", warnings)
        append_duplicate_colibri_codes(lines)
        lines.join("\n")
      end

      private

      def summary_lines
        [
          dry_run ? "[DRY RUN] Nenhuma alteração foi persistida." : "Importação concluída — alterações persistidas.",
          "Linhas lidas: #{total_rows}",
          "Criados: #{created}",
          "Atualizados: #{updated}",
          "Inalterados: #{unchanged}",
          "Inválidos: #{invalid.size}",
          "Avisos: #{warnings.size}",
          "Códigos Colibri duplicados entre produtos: #{duplicate_colibri_codes.size}"
        ]
      end

      def append_issues(lines, title, issues)
        return if issues.empty?

        lines << ""
        lines << "-- #{title} --"
        issues.each { |issue| lines << "  linha #{issue.row} (#{issue.code.presence || "sem código"}): #{issue.message}" }
      end

      def append_duplicate_colibri_codes(lines)
        return if duplicate_colibri_codes.empty?

        lines << ""
        lines << "-- Colibri duplicado entre produtos --"
        duplicate_colibri_codes.each do |code, product_codes|
          lines << "  colibri_code #{code}: #{product_codes.join(', ')}"
        end
      end
    end

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
    end

    def call
      rows = read_rows
      sectors_by_name = Sector.all.index_by(&:name)
      units_by_abbreviation = Unit.all.index_by(&:abbreviation)
      seen_codes = {}

      created = 0
      updated = 0
      unchanged = 0
      invalid = []
      warnings = []
      colibri_codes = Hash.new { |hash, key| hash[key] = [] }

      ActiveRecord::Base.transaction do
        rows.each do |row|
          outcome = process_row(
            row,
            sectors_by_name: sectors_by_name,
            units_by_abbreviation: units_by_abbreviation,
            seen_codes: seen_codes
          )

          if outcome[:status] == :invalid
            invalid << RowIssue.new(row: row[:row_number], code: row[:code], message: outcome[:message])
            next
          end

          case outcome[:status]
          when :created then created += 1
          when :updated then updated += 1
          when :unchanged then unchanged += 1
          end

          if outcome[:warning]
            warnings << RowIssue.new(row: row[:row_number], code: row[:code], message: outcome[:warning])
          end

          colibri_codes[outcome[:colibri_code]] << row[:code] if outcome[:colibri_code].present?
        end

        raise ActiveRecord::Rollback if @dry_run
      end

      Report.new(
        total_rows: rows.size,
        created: created,
        updated: updated,
        unchanged: unchanged,
        invalid: invalid,
        warnings: warnings,
        duplicate_colibri_codes: colibri_codes.select { |_code, product_codes| product_codes.size > 1 },
        dry_run: @dry_run
      )
    end

    private

    def read_rows
      sheet = Roo::Spreadsheet.open(@file_path).sheet(SHEET_NAME)
      header = sheet.row(1).map { |cell| cell.to_s.strip }

      (2..sheet.last_row).filter_map do |i|
        raw = header.zip(sheet.row(i)).to_h
        code = raw["Código"].to_s.strip
        name = raw["Produto"].to_s.strip
        next if code.empty? && name.empty?

        {
          row_number: i,
          code: code,
          name: name,
          sector_name: raw["Categoria"].to_s.strip,
          purchase_unit_abbr: raw["Unid. compra"].to_s.strip,
          stock_unit_abbr: raw["Unid. estoque"].to_s.strip,
          conversion_factor_raw: raw["Rendimento (estoque/compra)"],
          observations: raw["Observações"].to_s
        }
      end
    end

    def process_row(row, sectors_by_name:, units_by_abbreviation:, seen_codes:)
      return invalid_result("Código ausente") if row[:code].blank?
      return invalid_result("Produto (nome) ausente") if row[:name].blank?

      if (first_row = seen_codes[row[:code]])
        return invalid_result("Código duplicado na planilha (já processado na linha #{first_row})")
      end
      seen_codes[row[:code]] = row[:row_number]

      sector = sectors_by_name[row[:sector_name]]
      return invalid_result("Setor \"#{row[:sector_name]}\" não encontrado") unless sector

      purchase_unit = units_by_abbreviation[row[:purchase_unit_abbr]]
      unless purchase_unit
        return invalid_result("Unidade de compra \"#{row[:purchase_unit_abbr]}\" não encontrada")
      end

      stock_unit = units_by_abbreviation[row[:stock_unit_abbr]]
      unless stock_unit
        return invalid_result("Unidade de estoque \"#{row[:stock_unit_abbr]}\" não encontrada")
      end

      conversion_factor, warning = resolve_conversion_factor(row[:conversion_factor_raw])
      return invalid_result(warning) if conversion_factor.nil?

      persist_row(row, sector: sector, purchase_unit: purchase_unit, stock_unit: stock_unit,
                  conversion_factor: conversion_factor, warning: warning)
    end

    def persist_row(row, sector:, purchase_unit:, stock_unit:, conversion_factor:, warning:)
      colibri_code = extract_colibri_code(row[:observations])
      product = Product.find_or_initialize_by(code: row[:code])
      was_new = product.new_record?

      product.assign_attributes(
        name: row[:name],
        sector: sector,
        purchase_unit: purchase_unit,
        stock_unit: stock_unit,
        conversion_factor: conversion_factor,
        colibri_code: colibri_code
      )
      changed = product.changed?

      return invalid_result(product.errors.full_messages.to_sentence) unless product.save

      status = was_new ? :created : (changed ? :updated : :unchanged)
      { status: status, warning: warning, colibri_code: colibri_code }
    end

    def resolve_conversion_factor(raw)
      return [ 1, "Rendimento vazio — usando 1 como padrão" ] if raw.nil? || raw.to_s.strip.empty?

      value = raw.is_a?(Numeric) ? raw.to_f : Float(raw.to_s.strip.tr(",", "."), exception: false)
      return [ nil, "Rendimento inválido: #{raw.inspect}" ] if value.nil?
      return [ nil, "Rendimento deve ser positivo (recebido #{value})" ] if value <= 0

      [ value, nil ]
    end

    def extract_colibri_code(text)
      return nil if text.blank?

      match = COLIBRI_CODE_PATTERN.match(text)
      match && match[1]
    end

    def invalid_result(message)
      { status: :invalid, message: message }
    end
  end
end
