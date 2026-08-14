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
        counts = product_suppliers_counts_for(products)
        last_purchases = last_purchases_for(products)

        render json: {
          data: products.map do |product|
            ProductSerializer.call(
              product,
              product_suppliers_count: counts.fetch(product.id, 0),
              last_purchase: last_purchases[product.id]
            )
          end,
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      def show
        authorize! :show, @product

        render json: ProductSerializer.call(
          @product,
          product_suppliers_count: @product.product_suppliers.count,
          last_purchase: last_purchases_for([ @product ])[@product.id]
        ), status: :ok
      end

      def create
        authorize! :create, Product

        product = Product.new(product_params)

        if product.save
          # A brand-new product has no purchases yet — last_purchases_for
          # would correctly return nil too, but skipping the query entirely
          # is simpler and exactly as correct here.
          render json: ProductSerializer.call(product, product_suppliers_count: 0, last_purchase: nil), status: :created
        else
          render_unprocessable(product)
        end
      end

      def update
        authorize! :update, @product

        if @product.update(product_params)
          render json: ProductSerializer.call(
            @product,
            product_suppliers_count: @product.product_suppliers.count,
            last_purchase: last_purchases_for([ @product ])[@product.id]
          ), status: :ok
        else
          render_unprocessable(@product)
        end
      end

      def activate
        authorize! :activate, @product
        @product.update!(active: true)

        render json: ProductSerializer.call(
          @product,
          product_suppliers_count: @product.product_suppliers.count,
          last_purchase: last_purchases_for([ @product ])[@product.id]
        ), status: :ok
      end

      def deactivate
        authorize! :deactivate, @product
        @product.update!(active: false)

        render json: ProductSerializer.call(
          @product,
          product_suppliers_count: @product.product_suppliers.count,
          last_purchase: last_purchases_for([ @product ])[@product.id]
        ), status: :ok
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
        scope = scope.where(subcategory_id: params[:subcategory_id]) if params[:subcategory_id].present?

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

      # One extra query for the whole page instead of one per product (N+1)
      # — same reasoning/shape as SuppliersController#products_counts_for.
      def product_suppliers_counts_for(products)
        ProductSupplier.where(product_id: products.map(&:id)).group(:product_id).count
      end

      # Reproduces the source spreadsheet's "Preço/Data últ. compra" columns
      # (T/U in "Catálogo Mestre") exactly — see the Bloco 6H.4 analysis.
      # Those are formulas that pick the *last row entered* in the Histórico
      # sheet for a product, which is NOT the same as "the row with the
      # latest date": 171 product+date combinations in the real data have
      # more than one purchase on the same day, and 84 of those have
      # different prices between the tied rows — purchased_at alone would
      # pick an arbitrary one of them. DISTINCT ON with `id DESC` as the
      # tiebreaker reproduces the spreadsheet's answer exactly (verified
      # directly against the real data, including cross-supplier ties) — id
      # order is the app's equivalent of "which row was entered more
      # recently" now that the spreadsheet isn't the system of record.
      #
      # One query total regardless of how many products are passed in — safe
      # to call with the whole paginated page (avoids N+1) or with a single
      # product (show/create/update/activate/deactivate), never per-row.
      def last_purchases_for(products)
        PurchaseItem
          .joins(:purchase)
          .where(product_id: products.map(&:id))
          .select(
            "DISTINCT ON (purchase_items.product_id) purchase_items.product_id, " \
            "purchase_items.unit_price, purchases.purchased_at"
          )
          .order("purchase_items.product_id, purchases.purchased_at DESC, purchase_items.id DESC")
          .index_by(&:product_id)
      end
    end
  end
end
