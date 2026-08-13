module Api
  module V1
    class ProductStocksController < BaseController
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_product, only: %i[show update]

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

      private

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
