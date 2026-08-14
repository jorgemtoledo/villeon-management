module Importers
  # Imports the "Subcategoria" column (D) of the "Catálogo Mestre" sheet.
  # Read-only against the source file. The 25 codes found in the sheet
  # (ACU, ARO, BEB, ...) are the client's own classification — never
  # interpreted, translated or renamed here. Subcategory#code is the only
  # meaningful field; #name is set equal to #code (see Subcategory#name
  # comment in the migration) purely to satisfy the column, not as a
  # separate human label.
  #
  # Out of scope: Category (a separate, still-empty taxonomy the codes don't
  # belong to — see MakeSubcategoryCategoryOptional migration).
  class ProductSubcategoryImporter
    SHEET_NAME = "Catálogo Mestre".freeze

    RowIssue = Struct.new(:row, :product_code, :message, keyword_init: true)

    class Report
      attr_reader :total_rows, :subcategories_created, :linked, :unchanged, :without_subcategory,
                  :invalid, :dry_run

      def initialize(total_rows:, subcategories_created:, linked:, unchanged:, without_subcategory:,
                      invalid:, dry_run:)
        @total_rows = total_rows
        @subcategories_created = subcategories_created
        @linked = linked
        @unchanged = unchanged
        @without_subcategory = without_subcategory
        @invalid = invalid
        @dry_run = dry_run
      end

      def to_s
        lines = [
          dry_run ? "[DRY RUN] Nenhuma alteração foi persistida." : "Importação concluída — alterações persistidas.",
          "Linhas lidas: #{total_rows}",
          "Subcategorias criadas: #{subcategories_created}",
          "Produtos vinculados: #{linked}",
          "Produtos já vinculados corretamente (inalterados): #{unchanged}",
          "Produtos sem subcategoria na planilha: #{without_subcategory}",
          "Inválidos: #{invalid.size}"
        ]

        if invalid.any?
          lines << ""
          lines << "-- Linhas inválidas --"
          invalid.each { |issue| lines << "  linha #{issue.row} (#{issue.product_code.presence || "sem código"}): #{issue.message}" }
        end

        lines.join("\n")
      end
    end

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
    end

    def call
      rows = read_rows
      subcategories_created = 0
      linked = 0
      unchanged = 0
      without_subcategory = 0
      invalid = []

      ActiveRecord::Base.transaction do
        subcategories_by_code = {}

        rows.each do |row|
          if row[:subcategory_code].blank?
            without_subcategory += 1
            next
          end

          product = Product.find_by(code: row[:product_code])
          unless product
            invalid << RowIssue.new(row: row[:row_number], product_code: row[:product_code],
                                     message: "Produto \"#{row[:product_code]}\" não encontrado")
            next
          end

          subcategory = subcategories_by_code[row[:subcategory_code]]
          unless subcategory
            already_existed = Subcategory.exists?(code: row[:subcategory_code])
            subcategory = Subcategory.find_or_create_by!(code: row[:subcategory_code]) do |s|
              s.name = row[:subcategory_code]
            end
            subcategories_by_code[row[:subcategory_code]] = subcategory
            subcategories_created += 1 unless already_existed
          end

          if product.subcategory_id == subcategory.id
            unchanged += 1
          else
            product.update!(subcategory: subcategory)
            linked += 1
          end
        end

        raise ActiveRecord::Rollback if @dry_run
      end

      Report.new(
        total_rows: rows.size,
        subcategories_created: subcategories_created,
        linked: linked,
        unchanged: unchanged,
        without_subcategory: without_subcategory,
        invalid: invalid,
        dry_run: @dry_run
      )
    end

    private

    def read_rows
      sheet = Roo::Spreadsheet.open(@file_path).sheet(SHEET_NAME)
      header = sheet.row(1).map { |cell| cell.to_s.strip }

      (2..sheet.last_row).filter_map do |i|
        raw = header.zip(sheet.row(i)).to_h
        product_code = raw["Código"].to_s.strip
        next if product_code.empty?

        { row_number: i, product_code: product_code, subcategory_code: raw["Subcategoria"].to_s.strip }
      end
    end
  end
end
