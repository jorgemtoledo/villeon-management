module Api
  module V1
    class ProductSuppliersController < BaseController
      before_action :set_product
      before_action :set_product_supplier, only: %i[destroy prefer]

      # Structural data about the product (principal + alternate suppliers),
      # same read/write split as Product/Supplier: admin manages it, everyone
      # else (manager/operator) only reads. Not sector-scoped — unlike
      # Estoque, this isn't about who counts stock, it's catalog structure.
      def index
        authorize! :index, ProductSupplier

        scope = @product.product_suppliers
          .includes(:supplier)
          .references(:supplier)
          .order(preferred: :desc)
          .order("suppliers.name asc")

        render json: scope.map { |product_supplier| ProductSupplierSerializer.call(product_supplier) }, status: :ok
      end

      def create
        authorize! :create, ProductSupplier

        # Raises RecordNotFound (-> 404) for a supplier_id that doesn't
        # exist, distinct from the 422 a validation failure on the pivot
        # itself (e.g. duplicate link) would produce.
        Supplier.find(product_supplier_params[:supplier_id])

        product_supplier = @product.product_suppliers.new(product_supplier_params)

        ActiveRecord::Base.transaction do
          demote_current_preferred! if product_supplier.preferred
          product_supplier.save!
        end

        render json: ProductSupplierSerializer.call(product_supplier), status: :created
      rescue ActiveRecord::RecordInvalid
        render_unprocessable(product_supplier)
      end

      def destroy
        authorize! :destroy, @product_supplier

        # No promotion of another supplier to principal — a product can
        # legitimately have zero preferred suppliers (see business rule:
        # "0 ou 1 fornecedor principal"), decided and tested explicitly
        # rather than left as an accident of whatever query ran first.
        @product_supplier.destroy!

        head :no_content
      end

      # Promotes an existing alternate to principal. Demoting the current
      # principal (if any) happens automatically in the same transaction —
      # chosen over rejecting the request, since "trocar fornecedor
      # principal" is an explicit requirement and forcing a separate
      # unset-then-set round trip would be worse UX for no real benefit.
      def prefer
        authorize! :update, @product_supplier

        ActiveRecord::Base.transaction do
          demote_current_preferred!
          @product_supplier.update!(preferred: true)
        end

        render json: ProductSupplierSerializer.call(@product_supplier), status: :ok
      end

      private

      def set_product
        @product = Product.find(params[:product_id])
      end

      def set_product_supplier
        @product_supplier = @product.product_suppliers.find(params[:id])
      end

      def product_supplier_params
        params.require(:product_supplier).permit(:supplier_id, :preferred, :supplier_product_code, :notes)
      end

      def demote_current_preferred!
        @product.product_suppliers.where(preferred: true).update_all(preferred: false)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível vincular o fornecedor.", details: record.errors.full_messages },
               status: :unprocessable_content
      end
    end
  end
end
