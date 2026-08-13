module Api
  module V1
    # Whoami endpoint: proves the JWT auth flow end-to-end. Not gated by
    # CanCanCan — reading your own profile isn't a role-scoped permission,
    # authentication alone (inherited from ApplicationController) is enough.
    class MeController < BaseController
      def show
        render json: user_payload(current_user), status: :ok
      end

      private

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          active: user.active,
          all_sectors: user.all_sectors,
          sector_ids: user.sector_ids
        }
      end
    end
  end
end
