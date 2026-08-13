module Api
  module V1
    # Read-only: Unit is a small, mostly-static reference table (33 rows
    # today) used to populate Product's purchase_unit/stock_unit selects.
    # No pagination — the whole list is returned every time, sorted by name.
    class UnitsController < BaseController
      def index
        authorize! :index, Unit

        units = Unit.order(:name)

        render json: { data: units.map { |unit| UnitSerializer.call(unit) } }, status: :ok
      end
    end
  end
end
