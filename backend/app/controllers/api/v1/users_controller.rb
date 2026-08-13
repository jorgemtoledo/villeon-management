module Api
  module V1
    class UsersController < BaseController
      SORTABLE_COLUMNS = %w[name email created_at].freeze
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      before_action :set_user, only: %i[show update activate deactivate]

      def index
        authorize! :index, User

        scope = User.all
        scope = apply_search(scope)
        scope = apply_filters(scope)
        scope = apply_sort(scope)

        pagy, users = pagy(scope, limit: per_page_param)

        render json: { data: users.map { |user| UserSerializer.call(user) }, meta: pagination_meta(pagy) },
               status: :ok
      end

      def show
        authorize! :show, @user

        render json: UserSerializer.call(@user), status: :ok
      end

      def create
        authorize! :create, User

        user = User.new
        apply_user_params(user)

        if user.errors.empty? && user.save
          render json: UserSerializer.call(user), status: :created
        else
          render_unprocessable(user)
        end
      end

      def update
        authorize! :update, @user

        apply_user_params(@user)

        if @user.errors.empty? && @user.save
          render json: UserSerializer.call(@user), status: :ok
        else
          render_unprocessable(@user)
        end
      end

      def activate
        authorize! :activate, @user

        if @user.update(active: true)
          render json: UserSerializer.call(@user), status: :ok
        else
          render_unprocessable(@user)
        end
      end

      def deactivate
        authorize! :deactivate, @user

        if @user.update(active: false)
          render json: UserSerializer.call(@user), status: :ok
        else
          render_unprocessable(@user)
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      # active is deliberately not permitted here — same reasoning as
      # Product/Supplier: it only changes through activate/deactivate.
      def user_params
        params.require(:user).permit(
          :name, :email, :role, :all_sectors, :password, :password_confirmation, sector_ids: []
        )
      end

      # Two error classes bypass ActiveRecord validations entirely — they
      # raise on assignment, not on save — an unmapped role (Rails enum) and
      # a sector_ids value that doesn't resolve to real Sector rows. Both
      # get turned into ordinary validation errors so they render as the
      # same 422 shape as everything else instead of bubbling up as a 500.
      def apply_user_params(user)
        attributes = user_params
        sector_ids = attributes.delete(:sector_ids)

        if user.persisted? && attributes[:password].blank?
          # Devise's own password_required? checks !password.nil?, not
          # .present? — so passing through a blank "" would trip
          # "Password can't be blank" on every edit that isn't changing it.
          # Stripping both keys here is what actually implements "campos de
          # senha vazios não devem alterar a senha atual" on update; a blank
          # password on CREATE (user not yet persisted) is left untouched so
          # it still correctly fails as required.
          attributes = attributes.except(:password, :password_confirmation)
        end

        begin
          user.assign_attributes(attributes)
        rescue ArgumentError
          user.errors.add(:role, "é inválido")
        end

        return if sector_ids.nil?

        begin
          # .uniq: a repeated id in the same request carries no meaning (the
          # frontend's checkboxes can't even produce one) — treating [5, 5]
          # the same as [5] avoids a UserSector uniqueness validation
          # failure on the second, identical, in-memory-built row.
          user.sector_ids = sector_ids.uniq
        rescue ActiveRecord::RecordNotFound
          user.errors.add(:sector_ids, "contém um setor inexistente")
        end
      end

      def apply_search(scope)
        return scope if params[:q].blank?

        term = "%#{params[:q].strip}%"
        scope.where("users.name ILIKE :term OR users.email ILIKE :term", term: term)
      end

      def apply_filters(scope)
        scope = scope.where(role: params[:role]) if params[:role].present? && User.roles.key?(params[:role])

        if params[:active].present?
          scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
        end

        scope
      end

      def apply_sort(scope)
        column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "name"
        direction = params[:order].to_s.downcase == "desc" ? "desc" : "asc"

        scope.order("users.#{column} #{direction}")
      end

      def per_page_param
        value = params[:per_page].presence&.to_i || DEFAULT_PER_PAGE
        value.clamp(1, MAX_PER_PAGE)
      end

      def render_unprocessable(record)
        render json: { error: "Não foi possível salvar o usuário.", details: record.errors.full_messages },
               status: :unprocessable_content
      end
    end
  end
end
