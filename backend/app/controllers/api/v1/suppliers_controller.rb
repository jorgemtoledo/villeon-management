module Api
  module V1
    class SuppliersController < BaseController
      SORTABLE_COLUMNS = %w[name cnpj created_at].freeze
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_supplier, only: %i[show update activate deactivate products]

      def index
        authorize! :index, Supplier

        scope = Supplier.all
        scope = apply_search(scope)
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, suppliers = pagy(scope, limit: per_page_param)
        counts = products_counts_for(suppliers)

        render json: {
          data: suppliers.map { |supplier| SupplierSerializer.call(supplier, products_count: counts.fetch(supplier.id, 0)) },
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      def show
        authorize! :show, @supplier

        render json: SupplierSerializer.call(@supplier, products_count: @supplier.product_suppliers.count), status: :ok
      end

      def create
        authorize! :create, Supplier

        supplier = Supplier.new(supplier_params)

        if supplier.save
          render json: SupplierSerializer.call(supplier, products_count: 0), status: :created
        else
          render_unprocessable(supplier)
        end
      end

      def update
        authorize! :update, @supplier

        if @supplier.update(supplier_params)
          render json: SupplierSerializer.call(@supplier, products_count: @supplier.product_suppliers.count), status: :ok
        else
          render_unprocessable(@supplier)
        end
      end

      def activate
        authorize! :activate, @supplier
        @supplier.update!(active: true)

        render json: SupplierSerializer.call(@supplier, products_count: @supplier.product_suppliers.count), status: :ok
      end

      def deactivate
        authorize! :deactivate, @supplier
        @supplier.update!(active: false)

        render json: SupplierSerializer.call(@supplier, products_count: @supplier.product_suppliers.count), status: :ok
      end

      # Read-only: which products this supplier is linked to (ProductSupplier
      # pivot). Creating/editing/removing that link is out of scope for this
      # block — it lands with the real supplier import.
      def products
        authorize! :show, @supplier

        scope = @supplier.product_suppliers.includes(:product).references(:product).order("products.name asc")
        pagy, product_suppliers = pagy(scope, limit: per_page_param)

        render json: {
          data: product_suppliers.map { |product_supplier| SupplierProductSerializer.call(product_supplier) },
          meta: pagination_meta(pagy)
        }, status: :ok
      end

      private

      def set_supplier
        @supplier = Supplier.find(params[:id])
      end

      # active is deliberately not permitted here — same reasoning as
      # Product: it only changes through the dedicated activate/deactivate
      # endpoints, so a generic update can never flip it by accident.
      def supplier_params
        params.require(:supplier).permit(:name, :cnpj)
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        term = "%#{params[:q].strip}%"
        scope.where("suppliers.name ILIKE :term OR suppliers.cnpj ILIKE :term", term: term)
      end

      def apply_filters(scope)
        return scope if params[:active].blank?

        scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
        direction = params[:order].to_s.downcase == "desc" ? "desc" : "asc"

        scope.order("suppliers.#{column} #{direction}")
      end

      # One extra query for the whole page instead of one per supplier
      # (N+1) — Supplier has no counter_cache column, and grouping the main
      # paginated scope by suppliers.id would hand Pagy a Hash instead of an
      # Integer from #count, so this stays a separate, ungrouped query.
      def products_counts_for(suppliers)
        ProductSupplier.where(supplier_id: suppliers.map(&:id)).group(:supplier_id).count
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar o fornecedor.", details: record.errors.full_messages },
               status: :unprocessable_content
      end
    end
  end
end
