module Api
  module V1
    class StockCountsController < BaseController
      before_action :set_product, only: %i[create]
      before_action :set_stock_count, only: %i[update]

      # POST /api/v1/products/:product_id/stock_counts
      def create
        stock_count = @product.stock_counts.new(create_attrs)
        authorize! :create, stock_count

        if stock_count.save
          render json: StockCountSerializer.call(stock_count), status: :created
        else
          render_unprocessable(stock_count)
        end
      end

      # PATCH /api/v1/stock_counts/:id
      def update
        authorize! :update, @stock_count

        if @stock_count.update(update_attrs)
          render json: StockCountSerializer.call(@stock_count), status: :ok
        else
          render_unprocessable(@stock_count)
        end
      end

      private

      def set_product
        @product = Product.find(params[:product_id])
      end

      def set_stock_count
        @stock_count = StockCount.find(params[:id])
      end

      # user is always the authenticated caller — never client-supplied, so a
      # count can't be attributed to someone else via the request body.
      def create_attrs
        attrs = update_attrs
        attrs.merge(user: current_user, counted_at: attrs[:counted_at] || Time.current)
      end

      def update_attrs
        stock_count_params.to_h.symbolize_keys
      end

      def stock_count_params
        params.require(:stock_count).permit(:quantity, :counted_at)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar a contagem.", details: record.errors.full_messages },
               status: :unprocessable_content
      end
    end
  end
end
