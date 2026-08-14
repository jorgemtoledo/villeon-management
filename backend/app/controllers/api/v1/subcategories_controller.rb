module Api
  module V1
    # Read-only: Subcategory is a small reference table populated by
    # Importers::ProductSubcategoryImporter from the client's own "Subcategoria"
    # codes. No pagination, ordered by code — feeds the /produtos filter and
    # the ProductForm select.
    class SubcategoriesController < BaseController
      def index
        authorize! :index, Subcategory

        subcategories = Subcategory.order(:code)

        render json: { data: subcategories.map { |subcategory| SubcategorySerializer.call(subcategory) } },
               status: :ok
      end
    end
  end
end
