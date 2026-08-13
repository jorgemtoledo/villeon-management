module Importers
  # Imports Purchase/PurchaseItem rows from the "Histórico" sheet of the
  # client's MAPA COMPRAS.xlsx spreadsheet. Read-only against the source
  # file; the only writes are to Purchase and PurchaseItem — never creates
  # Product or Supplier (both must already exist, see ALIAS_MAP below).
  #
  # Histórico is a flat list of purchase LINES (2.306 of them), not
  # invoices — there is no invoice number column. Rows are grouped into a
  # Purchase by (supplier_id, purchased_at). This is an approximation: if
  # the same supplier genuinely delivered two separate invoices on the same
  # day, the source data has no way to tell them apart, and they get merged
  # into one Purchase here.
  #
  # Idempotency: Purchase is matched/created by (supplier_id, purchased_at)
  # and is NEVER destroyed/recreated — its id is stable across runs. Its
  # PurchaseItems ARE destroyed and rebuilt from the spreadsheet on every
  # run ("synced"), which is what makes re-running produce the same end
  # state without needing a per-line natural key (Histórico has none). This
  # also means the 69 byte-for-byte duplicate row pairs found during
  # reconciliation are preserved faithfully as two separate PurchaseItems —
  # they are never deduplicated.
  #
  # Fornecedor resolution: ALIAS_MAP below is the exact 27-alias + 2
  # resolved-ambiguous-case table approved during the Bloco 5E
  # reconciliation (see project memory "project-villeon-bloco5e-status").
  # A supplier name not found (via alias or exact normalized match) makes
  # the row invalid — never creates a new Supplier.
  class PurchaseHistoryImporter
    SHEET_NAME = "Histórico".freeze

    # 27 aliases approved after inspection (obvious nickname/abbreviation in
    # the free-text Fornecedor column of Histórico).
    APPROVED_ALIASES = {
      "Arosa (massa filo)" => "Arosa",
      "BRF (Sadia)" => "BRF (Sadia/Perdigão)",
      "CTrade (Caputo)" => "CTrade",
      "Casa Flora (WFB)?" => "Casa Flora",
      "Cintia (mesma da Obra Prima)" => "Obra Prima",
      "Coca-Cola (Spal)" => "Coca-Cola FEMSA (Spal)",
      "Coop. São João (Castellamare)" => "Coop. Vinícola São João",
      "DISABAL INDUSTRIA E COMER" => "Disabal",
      "Distribuidora Limão" => "Distrib. Limão",
      "Emfal" => "Emfal (álcool)",
      "Friboi" => "JBS (Friboi)",
      "HMF" => "HMF Alimentos",
      "Heineken" => "Heineken (HNK)",
      "Isar" => "Isar Alimentos",
      "Laticínios Piallet" => "Piallet",
      "MEC3" => "MEC3 (sorvetes)",
      "Manza" => "Manza Bebidas",
      "OESA (Imperial — adquirida)" => "OESA",
      "Perfa (ovos)" => "Perfa Atacado",
      "Rex Bibend (Maria Maria)?" => "Rex Bibend",
      "Tenuta Giarola" => "Tenuta Giarolla",
      "Três Corações" => "Café Três Corações",
      "Scala" => "Scalon & Cerchi",
      "Frescatto" => "Frigorífico Jahu",
      "Forte Distribuidora" => "L S Leone",
      "Frigorífico Imperatriz" => "Produtos Imperatriz",
      "Supernosso (Daqui Minas)" => "Decminas"
    }.freeze

    # 2 previously-ambiguous cases, resolved by explicit user decision
    # backed by CNPJ-root evidence found during reconciliation (see memory).
    RESOLVED_AMBIGUOUS = {
      "Dellys/Nova Safra (OESA)" => "OESA",
      "Sta Terezinha (Carapreta)" => "Frig. Santa Teresinha"
    }.freeze

    ALIAS_MAP = APPROVED_ALIASES.merge(RESOLVED_AMBIGUOUS).freeze

    RowIssue = Struct.new(:row, :detail, :message, keyword_init: true)

    class Report
      attr_reader :total_rows, :purchases_created, :purchases_updated, :items_created, :items_synced,
                  :invalid, :unresolved_suppliers, :unresolved_products, :duplicate_groups,
                  :total_amount_imported, :dry_run

      def initialize(total_rows:, purchases_created:, purchases_updated:, items_created:, items_synced:,
                      invalid:, unresolved_suppliers:, unresolved_products:, duplicate_groups:,
                      total_amount_imported:, dry_run:)
        @total_rows = total_rows
        @purchases_created = purchases_created
        @purchases_updated = purchases_updated
        @items_created = items_created
        @items_synced = items_synced
        @invalid = invalid
        @unresolved_suppliers = unresolved_suppliers
        @unresolved_products = unresolved_products
        @duplicate_groups = duplicate_groups
        @total_amount_imported = total_amount_imported
        @dry_run = dry_run
      end

      def purchases_count
        purchases_created + purchases_updated
      end

      def to_s
        lines = summary_lines
        append_issues(lines, "Linhas inválidas", invalid)
        append_issues(lines, "Fornecedores não resolvidos", unresolved_suppliers)
        append_issues(lines, "Produtos não resolvidos", unresolved_products)
        append_duplicate_groups(lines)
        lines.join("\n")
      end

      private

      def summary_lines
        [
          dry_run ? "[DRY RUN] Nenhuma alteração foi persistida." : "Importação concluída — alterações persistidas.",
          "Linhas lidas: #{total_rows}",
          "Purchases criados: #{purchases_created}",
          "Purchases atualizados: #{purchases_updated}",
          "Purchases gerados (total): #{purchases_count}",
          "PurchaseItems criados: #{items_created}",
          "PurchaseItems sincronizados: #{items_synced}",
          "Linhas inválidas: #{invalid.size}",
          "Fornecedores não resolvidos: #{unresolved_suppliers.size}",
          "Produtos não resolvidos: #{unresolved_products.size}",
          "Duplicidades exatas encontradas: #{duplicate_groups.size} grupos " \
            "(#{duplicate_groups.sum(&:size)} linhas) — preservadas, não deduplicadas",
          "Valor total importado: R$ #{format('%.2f', total_amount_imported)}"
        ]
      end

      def append_issues(lines, title, issues)
        return if issues.empty?

        lines << ""
        lines << "-- #{title} --"
        issues.each { |issue| lines << "  linha #{issue.row} (#{issue.detail}): #{issue.message}" }
      end

      def append_duplicate_groups(lines)
        return if duplicate_groups.empty?

        lines << ""
        lines << "-- Duplicidades exatas (linhas idênticas, preservadas como estão) --"
        duplicate_groups.each do |group|
          rows = group.map { |r| r[:row_number] }
          lines << "  #{group.first[:date_raw]} #{group.first[:code]} #{group.first[:supplier_raw]} -> linhas #{rows}"
        end
      end
    end

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
    end

    def call
      rows = read_rows
      products_by_code = Product.all.index_by(&:code)
      suppliers_by_norm = Supplier.all.index_by { |supplier| normalize_name(supplier.name) }
      existing_purchases = Purchase.all.index_by { |purchase| [ purchase.supplier_id, purchase.purchased_at.to_date ] }

      invalid = []
      unresolved_suppliers = []
      unresolved_products = []
      resolved_rows = []

      rows.each do |row|
        outcome = resolve_row(row, products_by_code: products_by_code, suppliers_by_norm: suppliers_by_norm)

        case outcome[:status]
        when :ok
          resolved_rows << outcome[:data]
        when :unresolved_supplier
          issue = RowIssue.new(row: row[:row_number], detail: row[:supplier_raw], message: outcome[:message])
          invalid << issue
          unresolved_suppliers << issue
        when :unresolved_product
          issue = RowIssue.new(row: row[:row_number], detail: row[:code], message: outcome[:message])
          invalid << issue
          unresolved_products << issue
        when :invalid
          invalid << RowIssue.new(row: row[:row_number], detail: row[:code], message: outcome[:message])
        end
      end

      duplicate_groups = detect_exact_duplicates(rows)

      purchases_created = 0
      purchases_updated = 0
      items_created = 0
      items_synced = 0
      total_amount_imported = BigDecimal("0")

      ActiveRecord::Base.transaction do
        resolved_rows.group_by { |r| [ r[:supplier].id, r[:date] ] }.each do |(supplier_id, date), group_rows|
          purchase = existing_purchases[[ supplier_id, date ]]
          was_new = purchase.nil?
          purchase ||= Purchase.new(supplier_id: supplier_id, purchased_at: date)

          # Purchase itself is preserved (find-or-create, never destroyed);
          # only its items are wiped and rebuilt — this is what makes the
          # importer idempotent without a natural per-line key, and why the
          # 69 exact-duplicate row pairs stay duplicated (no dedup here).
          purchase.purchase_items.destroy_all if purchase.persisted?

          group_total = BigDecimal("0")
          group_rows.each do |r|
            item = purchase.purchase_items.build(product: r[:product], quantity: r[:quantity], unit_price: r[:unit_price])
            # Read quantity/unit_price back from the built item, not from
            # `r` directly: ActiveRecord casts them to purchase_items'
            # actual column scale (4 decimals) the instant they're
            # assigned, same as what PurchaseItem#calculate_total_price
            # will use for total_price. The spreadsheet can carry more
            # precision than that column stores (e.g. "3.666667") — using
            # `r`'s raw, higher-precision value here would multiply
            # differently than the item's own callback does and drift
            # total_amount away from SUM(total_price) by a cent. Matching
            # the cast precision is what guarantees they're always equal.
            group_total += (item.quantity * item.unit_price).round(2)
          end
          # Purchase.total_amount is always derived from the items just
          # built (quantity × unit_price per line, summed) — the
          # spreadsheet's own "Total (R$)" column is never trusted directly.
          purchase.total_amount = group_total

          purchase.save!

          if was_new
            purchases_created += 1
            items_created += group_rows.size
          else
            purchases_updated += 1
            items_synced += group_rows.size
          end
          total_amount_imported += group_total
        end

        raise ActiveRecord::Rollback if @dry_run
      end

      Report.new(
        total_rows: rows.size,
        purchases_created: purchases_created,
        purchases_updated: purchases_updated,
        items_created: items_created,
        items_synced: items_synced,
        invalid: invalid,
        unresolved_suppliers: unresolved_suppliers,
        unresolved_products: unresolved_products,
        duplicate_groups: duplicate_groups,
        total_amount_imported: total_amount_imported,
        dry_run: @dry_run
      )
    end

    private

    def read_rows
      sheet = Roo::Spreadsheet.open(@file_path).sheet(SHEET_NAME)
      header = sheet.row(1).map { |cell| cell.to_s.strip }

      (2..sheet.last_row).filter_map do |i|
        raw = header.zip(sheet.row(i)).to_h
        date_raw = raw["Data"].to_s.strip
        code = raw["Código"].to_s.strip
        supplier_raw = raw["Fornecedor"].to_s.strip
        next if date_raw.empty? && code.empty? && supplier_raw.empty?

        {
          row_number: i,
          date_raw: date_raw,
          code: code,
          supplier_raw: supplier_raw,
          quantity_raw: raw["Qtd comprada"],
          unit_price_raw: raw["Preço unit. (R$)"],
          total_raw: raw["Total (R$)"]
        }
      end
    end

    def resolve_row(row, products_by_code:, suppliers_by_norm:)
      date = parse_date(row[:date_raw])
      return { status: :invalid, message: "Data inválida: #{row[:date_raw].inspect}" } unless date

      product = products_by_code[row[:code]]
      unless product
        return { status: :unresolved_product, message: "Produto com código \"#{row[:code]}\" não encontrado" }
      end

      supplier_target = ALIAS_MAP[row[:supplier_raw]] || row[:supplier_raw]
      supplier = suppliers_by_norm[normalize_name(supplier_target)]
      unless supplier
        return { status: :unresolved_supplier, message: "Fornecedor \"#{row[:supplier_raw]}\" não resolvido" }
      end

      quantity = numeric(row[:quantity_raw])
      return { status: :invalid, message: "Quantidade inválida: #{row[:quantity_raw].inspect}" } unless quantity&.positive?

      unit_price = numeric(row[:unit_price_raw])
      return { status: :invalid, message: "Preço unitário inválido: #{row[:unit_price_raw].inspect}" } if unit_price.nil? || unit_price.negative?

      { status: :ok, data: { supplier: supplier, product: product, date: date, quantity: quantity, unit_price: unit_price } }
    end

    def detect_exact_duplicates(rows)
      groups = rows.group_by { |r| [ r[:date_raw], r[:code], r[:supplier_raw], r[:quantity_raw], r[:unit_price_raw], r[:total_raw] ] }
      groups.values.select { |group| group.size > 1 }
    end

    def parse_date(value)
      Date.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def numeric(value)
      return value.to_d if value.is_a?(Numeric)
      return nil if value.to_s.strip.empty?

      Float(value.to_s.strip.tr(",", "."), exception: false)&.to_d
    end

    def normalize_name(value)
      I18n.transliterate(value.to_s).strip.downcase.gsub(/[^a-z0-9 ]/, "").squeeze(" ")
    end
  end
end
