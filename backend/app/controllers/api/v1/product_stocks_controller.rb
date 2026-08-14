module Api
  module V1
    class ProductStocksController < BaseController
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_product, only: %i[show update update_priority]

      # GET /api/v1/product_stocks?sector_id=X
      # Sector defaults to the current user's own sectors when not given
      # explicitly; requesting a sector outside the user's access is a 403,
      # never a silently-filtered empty result — a client can't discover
      # another sector's stock just by trying its id.
      def index
        authorize! :index, ProductStock

        scope = Product.includes(:sector, :purchase_unit, :stock_unit, :product_stock)
        scope = scope.where(sector_id: resolved_sector_ids) if resolved_sector_ids
        scope = apply_active_filter(scope)

        pagy, products = pagy(scope.order(:name), limit: per_page_param)
        counted_ids = counted_product_ids_for(products)

        render json: {
          data: products.map { |product| ProductStockSerializer.call(product, counted: counted_ids.include?(product.id)) },
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      # GET /api/v1/products/:product_id/stock
      def show
        # Authorize against a *duplicate* of @product, never @product itself:
        # Rails' automatic inverse_of detection means assigning a new
        # ProductStock's `product` to @product directly (e.g. via
        # @product.build_product_stock, or even ProductStock.new(product: @product))
        # also writes that unsaved record into @product's own has_one cache —
        # which would make @product.product_stock stop returning nil right
        # after, breaking StockCalculator's "never counted" detection below.
        # A dup carries the same sector_id (all the hash-condition check
        # needs) without being the same object @product's cache points at.
        stock_record = @product.product_stock || ProductStock.new(product: @product.dup)
        authorize! :show, stock_record

        render json: ProductStockSerializer.call(@product), status: :ok
      end

      # PATCH /api/v1/products/:product_id/stock
      # Structural config (minimum_quantity/ideal_quantity) — admin-only.
      # Unlike show/index, there is no sector-scoped `can`, so class-level
      # authorize! already denies manager/operator entirely, regardless of
      # which sector the product belongs to.
      def update
        stock = @product.product_stock || @product.build_product_stock
        authorize! :update, stock

        if stock.update(stock_params)
          render json: ProductStockSerializer.call(@product), status: :ok
        else
          render_unprocessable(stock)
        end
      end

      # PATCH /api/v1/products/:product_id/stock/priority
      # Bloco 6G Parte 4: priority/needs_advance_order. Separate from
      # `update` above on purpose — that action is admin-only structural
      # config (minimum/ideal); this one is sector-scoped and, unlike every
      # other Ability rule in the app, its authorization also depends on the
      # row's *current* data (already set once, by someone other than
      # admin/manager, locks it) — CanCan's hash conditions can't express
      # "was this already set", so that half of the check lives here.
      def update_priority
        stock = @product.product_stock || @product.build_product_stock
        authorize! :update_priority, stock
        raise CanCan::AccessDenied if locked_for_current_user?(stock)

        previous_priority = stock.priority
        previous_advance_order = stock.needs_advance_order

        begin
          stock.assign_attributes(priority_params)
        rescue ArgumentError
          stock.errors.add(:priority, "é inválido")
        end

        if stock.errors.empty? && stock.save
          record_priority_audit!(stock, previous_priority, previous_advance_order)
          render json: ProductStockSerializer.call(@product), status: :ok
        else
          render_unprocessable(stock)
        end
      end

      private

      # Bloco Histórico: one entry per field that actually changed — a save
      # that only touches one of the two (or neither, e.g. re-saving the same
      # values) never creates a fake entry for the untouched field, since
      # `saved_change_to_*?` only reflects a real value change.
      def record_priority_audit!(stock, previous_priority, previous_advance_order)
        if stock.saved_change_to_priority?
          StockAuditEntry.create!(product: @product, user: current_user, field: "priority",
                                    previous_value: previous_priority, new_value: stock.priority)
        end

        return unless stock.saved_change_to_needs_advance_order?

        StockAuditEntry.create!(
          product: @product, user: current_user, field: "needs_advance_order",
          previous_value: previous_advance_order.nil? ? nil : previous_advance_order.to_s,
          new_value: stock.needs_advance_order.nil? ? nil : stock.needs_advance_order.to_s
        )
      end

      # Only admin/manager can touch a value someone already saved — an
      # unsaved (never-configured) stock, or one where both fields are still
      # nil, is always open to whoever the Ability rule already let through
      # (sector-scoped operator included).
      def locked_for_current_user?(stock)
        return false if current_user.admin? || current_user.manager?

        stock.persisted? && (stock.priority.present? || !stock.needs_advance_order.nil?)
      end

      def priority_params
        params.require(:product_stock).permit(:priority, :needs_advance_order)
      end

      def set_product
        @product = Product.find(params[:product_id])
      end

      def stock_params
        params.require(:product_stock).permit(:minimum_quantity, :ideal_quantity)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar a configuração de estoque.", details: record.errors.full_messages },
               status: :unprocessable_content
      end

      def counted_product_ids_for(products)
        StockCount.where(product_id: products.map(&:id)).distinct.pluck(:product_id).to_set
      end

      def resolved_sector_ids
        return nil if current_user.has_all_sector_access? && params[:sector_id].blank?

        if params[:sector_id].present?
          requested_id = params[:sector_id].to_i
          unless current_user.has_all_sector_access? || current_user.sector_ids.include?(requested_id)
            raise CanCan::AccessDenied
          end

          [ requested_id ]
        else
          current_user.sector_ids
        end
      end

      def apply_active_filter(scope)
        return scope if params[:active].blank?

        scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end
    end
  end
end
