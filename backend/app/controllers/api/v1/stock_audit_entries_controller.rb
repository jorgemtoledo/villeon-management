module Api
  module V1
    # Read-only: StockAuditEntry rows are only ever created as a side effect
    # of StockCount#sync_product_stock! and
    # ProductStocksController#update_priority (Bloco Histórico) — there's no
    # write action here on purpose, matching the "imutável, sem edição/
    # exclusão" requirement.
    class StockAuditEntriesController < BaseController
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_product, if: -> { params[:product_id].present? }

      # GET /api/v1/stock_audit_entries
      # GET /api/v1/products/:product_id/stock_audit_entries
      # Both routes hit this same action — the nested one just pre-fills
      # product_id via set_product, everything else (filters, ordering,
      # pagination) is identical either way.
      def index
        authorize! :index, StockAuditEntry

        scope = StockAuditEntry.includes(:product, :user)
        scope = scope.where(product_id: @product.id) if @product
        scope = apply_filters(scope)
        scope = scope.order(created_at: :desc, id: :desc)

        pagy, entries = pagy(scope, limit: per_page_param)

        render json: {
          data: entries.map { |entry| StockAuditEntrySerializer.call(entry) },
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      # GET /api/v1/stock_audit_entries/users
      # Only the users who actually have at least one entry — feeds the
      # "Usuário" filter select. Deliberately not the full /api/v1/users
      # roster (admin-only, Bloco 6F) — this stays scoped to what a manager
      # calling this endpoint is already allowed to see.
      def users
        authorize! :index, StockAuditEntry

        rows = StockAuditEntry.joins(:user).distinct.order("users.name").pluck("users.id", "users.name")

        render json: { data: rows.map { |id, name| { id: id, name: name } } }, status: :ok
      end

      private

      def set_product
        @product = Product.find(params[:product_id])
      end

      def apply_filters(scope)
        scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
        scope = scope.where(field: params[:field]) if params[:field].present?
        scope = apply_product_search(scope)
        scope = apply_date_range(scope)
        scope
      end

      def apply_product_search(scope)
        return scope if params[:q].blank?

        term = "%#{params[:q].strip}%"
        scope.joins(:product).where("products.name ILIKE :term OR products.code ILIKE :term", term: term)
      end

      def apply_date_range(scope)
        from = parse_date(params[:date_from])
        scope = scope.where("stock_audit_entries.created_at >= ?", from.beginning_of_day) if from

        to = parse_date(params[:date_to])
        scope = scope.where("stock_audit_entries.created_at <= ?", to.end_of_day) if to

        scope
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value)
      rescue ArgumentError
        nil
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end
    end
  end
end
