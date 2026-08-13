module Api
  module V1
    class PurchasesController < BaseController
      SORTABLE_COLUMNS = %w[purchased_at total_amount created_at].freeze
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      def index
        authorize! :index, Purchase

        scope = Purchase.includes(:supplier).references(:supplier)
        scope = apply_search(scope)
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, purchases = pagy(scope, limit: per_page_param)
        counts = items_counts_for(purchases)

        render json: {
          data: purchases.map { |purchase| PurchaseSerializer.call(purchase, items_count: counts.fetch(purchase.id, 0)) },
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      def show
        purchase = Purchase.includes(:supplier, purchase_items: { product: :purchase_unit }).find(params[:id])
        authorize! :show, purchase

        render json: PurchaseDetailSerializer.call(purchase), status: :ok
      end

      # Registering a purchase never touches stock (ProductStock/StockCount) —
      # that only happens through StockCount, per the Bloco 6G rule. Only
      # Purchase + PurchaseItems are written here.
      def create
        authorize! :create, Purchase

        attrs = purchase_params
        items_params = attrs.delete(:items) || []

        purchase = Purchase.new(attrs)

        if items_params.blank?
          purchase.errors.add(:purchase_items, "não pode ficar em branco")
          return render_unprocessable(purchase)
        end

        # total_amount is never trusted from the client (it isn't even
        # permitted below) — it's the sum of each item's own quantity *
        # unit_price, rounded to the same 2-decimal scale as
        # PurchaseItem#total_price (Bloco 5E rule), so it always matches
        # SUM(PurchaseItem.total_price) exactly.
        total = BigDecimal("0")
        items_params.each do |item_attrs|
          item = purchase.purchase_items.build(item_attrs)
          total += (item.quantity * item.unit_price).round(2) if item.quantity.present? && item.unit_price.present?
        end
        purchase.total_amount = total

        if purchase.save
          purchase = Purchase.includes(:supplier, purchase_items: { product: :purchase_unit }).find(purchase.id)
          render json: PurchaseDetailSerializer.call(purchase), status: :created
        else
          render_unprocessable(purchase)
        end
      end

      # Editing a purchase never touches stock either — same rule as create.
      # Items are fully replaced (destroy + rebuild from the submitted array)
      # rather than diffed, exactly like PurchaseHistoryImporter's "sync"
      # (Bloco 5E) — this is what lets adding/removing/changing items share
      # one code path, and it never deduplicates: if the client resubmits
      # the same two values twice (e.g. an existing exact-duplicate pair
      # from the Histórico import), both come back as two separate rows,
      # because nothing here groups or uniqs the incoming array.
      def update
        purchase = Purchase.find(params[:id])
        authorize! :update, purchase

        attrs = purchase_params
        items_params = attrs.delete(:items) || []

        if items_params.blank?
          purchase.errors.add(:purchase_items, "não pode ficar em branco")
          return render_unprocessable(purchase)
        end

        purchase.assign_attributes(attrs)

        saved = false
        ActiveRecord::Base.transaction do
          purchase.purchase_items.destroy_all

          total = BigDecimal("0")
          items_params.each do |item_attrs|
            item = purchase.purchase_items.build(item_attrs)
            total += (item.quantity * item.unit_price).round(2) if item.quantity.present? && item.unit_price.present?
          end
          purchase.total_amount = total

          if purchase.save
            saved = true
          else
            raise ActiveRecord::Rollback
          end
        end

        if saved
          purchase = Purchase.includes(:supplier, purchase_items: { product: :purchase_unit }).find(purchase.id)
          render json: PurchaseDetailSerializer.call(purchase), status: :ok
        else
          render_unprocessable(purchase)
        end
      end

      private

      def purchase_params
        params.require(:purchase).permit(:supplier_id, :purchased_at, :invoice_number, items: %i[product_id quantity unit_price])
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar a compra.", details: record.errors.full_messages },
               status: :unprocessable_content
      end

      # Invoice numbers aren't populated by the current import (see Bloco 6D
      # analysis), but the column exists for future manual entries — matching
      # it here costs nothing today and avoids a second migration later.
      def apply_search(scope)
        return scope if params[:q].blank?

        term = "%#{params[:q].strip}%"
        scope.where("suppliers.name ILIKE :term OR purchases.invoice_number ILIKE :term", term: term)
      end

      def apply_filters(scope)
        scope = scope.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
        scope = scope.where("purchases.purchased_at >= ?", parse_date(params[:date_from]).beginning_of_day) if parse_date(params[:date_from])
        scope = scope.where("purchases.purchased_at <= ?", parse_date(params[:date_to]).end_of_day) if parse_date(params[:date_to])

        scope
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "purchased_at"
        direction = params[:order].to_s.downcase == "asc" ? "asc" : "desc"

        scope.order("purchases.#{column} #{direction}")
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value)
      rescue ArgumentError
        nil
      end

      # One extra query for the whole page instead of one per purchase
      # (N+1) — same reasoning as SuppliersController#products_counts_for:
      # grouping the main paginated scope by purchases.id would hand Pagy a
      # Hash instead of an Integer from #count.
      def items_counts_for(purchases)
        PurchaseItem.where(purchase_id: purchases.map(&:id)).group(:purchase_id).count
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end
    end
  end
end
