module Importers
  # Imports Supplier rows from the "Fornecedores" sheet of the client's
  # MAPA COMPRAS.xlsx spreadsheet. Read-only against the source file; the
  # only writes are to Supplier.
  #
  # "De-Para Fornecedores" is never imported as its own records — it only
  # has an 8-digit CNPJ *root* (not a full, checksum-valid 14-digit CNPJ),
  # with mixed confidence ("PROPOSTO"/"PERGUNTAR" rows aren't confirmed by
  # the client). It's read here purely to annotate the report with a
  # candidate root per supplier, for a future manual/CNPJ-based
  # reconciliation — never persisted to Supplier#cnpj.
  #
  # Idempotency: normally CNPJ would be the dedup key (see
  # ProductCatalogImporter's `code`), but no supplier here has one yet —
  # falls back to normalized `name`. Documented limitation: renaming a
  # supplier in the spreadsheet later will create a new row here instead of
  # updating the existing one, until real CNPJs make CNPJ-based
  # reconciliation possible.
  #
  # Out of scope for this importer (Bloco 5D): razão social, categoria,
  # contato, cadência, gasto/ticket médio (these have no Supplier column and
  # are left for a future supplier/purchasing-management block — spend and
  # average ticket specifically should come from real Purchase history, not
  # be persisted as spreadsheet snapshots), and any ProductSupplier linking.
  class SupplierImporter
    SUPPLIERS_SHEET_NAME = "Fornecedores".freeze
    DEPARA_SHEET_NAME = "De-Para Fornecedores".freeze
    CNPJ_ROOT_LENGTH = 8

    RowIssue = Struct.new(:row, :name, :message, keyword_init: true)
    CnpjRootCandidate = Struct.new(:row, :name, :cnpj_root, keyword_init: true)

    class Report
      attr_reader :total_rows, :divider_rows, :created, :updated, :unchanged, :invalid,
                  :duplicate_names, :cnpj_root_candidates, :dry_run

      def initialize(total_rows:, divider_rows:, created:, updated:, unchanged:, invalid:,
                      duplicate_names:, cnpj_root_candidates:, dry_run:)
        @total_rows = total_rows
        @divider_rows = divider_rows
        @created = created
        @updated = updated
        @unchanged = unchanged
        @invalid = invalid
        @duplicate_names = duplicate_names
        @cnpj_root_candidates = cnpj_root_candidates
        @dry_run = dry_run
      end

      def to_s
        lines = summary_lines
        append_issues(lines, "Linhas inválidas", invalid)
        append_issues(lines, "Nomes duplicados na planilha", duplicate_names)
        append_cnpj_root_candidates(lines)
        lines.join("\n")
      end

      private

      def summary_lines
        [
          dry_run ? "[DRY RUN] Nenhuma alteração foi persistida." : "Importação concluída — alterações persistidas.",
          "Linhas lidas (fornecedores válidos): #{total_rows}",
          "Linhas divisoras ignoradas: #{divider_rows}",
          "Criados: #{created}",
          "Atualizados: #{updated}",
          "Inalterados: #{unchanged}",
          "Inválidos: #{invalid.size}",
          "Nomes duplicados na planilha: #{duplicate_names.size}",
          "Candidatos de raiz de CNPJ (De-Para) — apenas informativo, não persistido: " \
            "#{cnpj_root_candidates.size} de #{total_rows}",
          "",
          "LIMITAÇÃO: nenhum fornecedor tem CNPJ completo válido ainda — a chave de " \
            "idempotência desta importação é o nome normalizado, não CNPJ. Se um fornecedor " \
            "for renomeado na planilha antes de termos CNPJs completos, rodar de novo criará " \
            "um registro novo em vez de atualizar o existente."
        ]
      end

      def append_issues(lines, title, issues)
        return if issues.empty?

        lines << ""
        lines << "-- #{title} --"
        issues.each { |issue| lines << "  linha #{issue.row} (#{issue.name.presence || "sem nome"}): #{issue.message}" }
      end

      def append_cnpj_root_candidates(lines)
        return if cnpj_root_candidates.empty?

        lines << ""
        lines << "-- Candidatos de raiz de CNPJ (De-Para Fornecedores, só para referência futura) --"
        cnpj_root_candidates.each do |candidate|
          lines << "  linha #{candidate.row} (#{candidate.name}): raiz #{candidate.cnpj_root}"
        end
      end
    end

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
      @divider_rows_count = 0
    end

    def call
      rows = read_rows
      existing_by_normalized_name = Supplier.all.index_by { |supplier| normalize_name(supplier.name) }
      seen_names = {}

      created = 0
      updated = 0
      unchanged = 0
      invalid = []
      duplicate_names = []
      cnpj_root_candidates = []

      ActiveRecord::Base.transaction do
        rows.each do |row|
          if (first_row = seen_names[normalize_name(row[:name])])
            duplicate_names << RowIssue.new(
              row: row[:row_number], name: row[:name],
              message: "Nome duplicado na planilha (já processado na linha #{first_row})"
            )
            next
          end
          seen_names[normalize_name(row[:name])] = row[:row_number]

          outcome = persist_row(row, existing_by_normalized_name: existing_by_normalized_name)

          if outcome[:status] == :invalid
            invalid << RowIssue.new(row: row[:row_number], name: row[:name], message: outcome[:message])
            next
          end

          case outcome[:status]
          when :created then created += 1
          when :updated then updated += 1
          when :unchanged then unchanged += 1
          end

          if row[:cnpj_root_candidate].present?
            cnpj_root_candidates << CnpjRootCandidate.new(
              row: row[:row_number], name: row[:name], cnpj_root: row[:cnpj_root_candidate]
            )
          end
        end

        raise ActiveRecord::Rollback if @dry_run
      end

      Report.new(
        total_rows: rows.size,
        divider_rows: @divider_rows_count,
        created: created,
        updated: updated,
        unchanged: unchanged,
        invalid: invalid,
        duplicate_names: duplicate_names,
        cnpj_root_candidates: cnpj_root_candidates,
        dry_run: @dry_run
      )
    end

    private

    def read_rows
      spreadsheet = Roo::Spreadsheet.open(@file_path)

      # Roo::Spreadsheet#sheet mutates and returns the SAME object (just
      # repoints its internal "current sheet"), it does not hand back an
      # independent per-sheet accessor — confirmed via `a.equal?(b) => true`
      # after `a = xlsx.sheet(x); b = xlsx.sheet(y)`. Interleaving #row/
      # #last_row calls across two sheets on that shared object silently
      # reads whichever sheet was opened *last*. Each sheet is therefore
      # fully drained into a plain Array here before the other is opened.
      depara_sheet = spreadsheet.sheet(DEPARA_SHEET_NAME)
      depara_rows = (1..depara_sheet.last_row).map { |i| depara_sheet.row(i) }

      suppliers_sheet = spreadsheet.sheet(SUPPLIERS_SHEET_NAME)
      suppliers_rows = (1..suppliers_sheet.last_row).map { |i| suppliers_sheet.row(i) }

      cnpj_root_lookup = build_cnpj_root_lookup(depara_rows)
      header = suppliers_rows.first.map { |cell| cell.to_s.strip }

      (1...suppliers_rows.size).filter_map do |index|
        i = index + 1
        full_row = suppliers_rows[index]
        name = full_row[0].to_s.strip
        next if name.empty?

        # Structural divider rule (not text-matching): Nome curto filled in,
        # every other column blank — e.g. "SEM NOTA FISCAL EM 2026 —
        # verificar se ativos / de-para" at row 66 of the real file.
        if full_row[1..].all? { |cell| cell.nil? || cell.to_s.strip.empty? }
          @divider_rows_count += 1
          next
        end

        raw = header.zip(full_row).to_h
        razao_social = raw["Razão social (NF-e)"].to_s.strip
        candidate = cnpj_root_lookup[normalize_name(razao_social)] || cnpj_root_lookup[normalize_name(name)]

        { row_number: i, name: name, cnpj_root_candidate: candidate }
      end
    end

    # Builds a lookup (normalized razão social/nome fantasia -> 8-digit CNPJ
    # root) from "De-Para Fornecedores", for report annotation only. Rows
    # without a well-formed 8-digit root are skipped — this naturally
    # excludes the sheet's blank spacer row and its trailing legend/footnote
    # row (a long free-text cell, not a root) without hardcoding either.
    def build_cnpj_root_lookup(depara_rows)
      header = depara_rows.first.map { |cell| cell.to_s.strip }
      lookup = {}

      depara_rows[1..].each do |data_row|
        raw = header.zip(data_row).to_h
        root = raw["CNPJ (raiz)"].to_s.strip
        next unless root.length == CNPJ_ROOT_LENGTH

        razao_key = normalize_name(raw["Razão social (como vem na NF-e)"].to_s)
        fantasia_key = normalize_name(raw["Nome fantasia (equipe)"].to_s)
        lookup[razao_key] = root if razao_key.present?
        lookup[fantasia_key] ||= root if fantasia_key.present?
      end

      lookup
    end

    def persist_row(row, existing_by_normalized_name:)
      return invalid_result("Nome ausente") if row[:name].blank?

      key = normalize_name(row[:name])
      supplier = existing_by_normalized_name[key] || Supplier.new(cnpj: nil, active: true)
      was_new = supplier.new_record?

      supplier.name = row[:name]
      changed = supplier.changed?

      return invalid_result(supplier.errors.full_messages.to_sentence) unless supplier.save

      { status: was_new ? :created : (changed ? :updated : :unchanged) }
    end

    # Transliterates accents before stripping punctuation — without this,
    # "Importação" and "Importacao" would normalize to different keys
    # ("importao" vs "importacao", since dropping ç/ã outright shortens the
    # word instead of folding them to c/a) and silently fail to match.
    def normalize_name(value)
      I18n.transliterate(value.to_s).strip.downcase.gsub(/[^a-z0-9 ]/, "").squeeze(" ")
    end

    def invalid_result(message)
      { status: :invalid, message: message }
    end
  end
end
