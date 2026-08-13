module Api
  module V1
    class ProductsController < BaseController
      SORTABLE_COLUMNS = %w[name code created_at].freeze
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_product, only: %i[show update activate deactivate]

      def index
        authorize! :index, Product

        scope = Product.includes(:sector, :category, :subcategory, :purchase_unit, :stock_unit)
        scope = apply_search(scope)
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, products = pagy(scope, limit: per_page_param)

        render json: { data: products.map { |product| ProductSerializer.call(product) }, meta: pagination_meta(pagy) },
               status: :ok
      end

      def show
        authorize! :show, @product

        render json: ProductSerializer.call(@product), status: :ok
      end

      def create
        authorize! :create, Product

        product = Product.new(product_params)

        if product.save
          render json: ProductSerializer.call(product), status: :created
        else
          render_unprocessable(product)
        end
      end

      def update
        authorize! :update, @product

        if @product.update(product_params)
          render json: ProductSerializer.call(@product), status: :ok
        else
          render_unprocessable(@product)
        end
      end

      def activate
        authorize! :activate, @product
        @product.update!(active: true)

        render json: ProductSerializer.call(@product), status: :ok
      end

      def deactivate
        authorize! :deactivate, @product
        @product.update!(active: false)

        render json: ProductSerializer.call(@product), status: :ok
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      # active is deliberately not permitted here — it only changes through
      # the dedicated activate/deactivate endpoints, so a generic update can
      # never flip it by accident (or by a role that shouldn't be able to).
      def product_params
        params.require(:product).permit(
          :name, :code, :colibri_code, :sector_id, :category_id, :subcategory_id,
          :purchase_unit_id, :stock_unit_id, :conversion_factor
        )
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        term = "%#{params[:q].strip}%"
        scope.where("products.name ILIKE :term OR products.code ILIKE :term", term: term)
      end

      def apply_filters(scope)
        scope = scope.where(sector_id: params[:sector_id]) if params[:sector_id].present?

        if params[:active].present?
          scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
        end

        scope
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
        direction = params[:order].to_s.downcase == "desc" ? "desc" : "asc"

        scope.order("#{column} #{direction}")
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar o produto.", details: record.errors.full_messages },
               status: :unprocessable_content
      end
    end
  end
end
