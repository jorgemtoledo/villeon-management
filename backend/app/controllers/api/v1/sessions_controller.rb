module Api
  module V1
    class SessionsController < Devise::SessionsController
      # Devise's authenticate_user! silently no-ops inside any devise_controller?
      # (this one included) unless called with force: true — so the global
      # before_action from ApplicationController never actually gates #create
      # or #destroy here, and Devise's own "already signed out?" safety net
      # (verify_signed_out_user) checks warden.user(run_callbacks: false),
      # which doesn't correctly see a stateless JWT as "signed in" either.
      # Skip that broken check and force real authentication explicitly for
      # #destroy — you must present a valid, non-revoked token to log out.
      # #create stays reachable without a token (that's the whole point of login).
      skip_before_action :verify_signed_out_user, only: :destroy
      prepend_before_action -> { authenticate_user!(force: true) }, only: :destroy

      private

      # The JWT itself is never in the response body — only in the
      # `Authorization: Bearer <token>` response header (devise-jwt, via
      # config.jwt.dispatch_requests matching this route).
      def respond_with(resource, _opts = {})
        render json: { user: user_payload(resource) }, status: :ok
      end

      # Devise's default respond_to_on_destroy calls `respond_to do |format|`,
      # which ActionController::API doesn't provide — override with a plain
      # head. DELETE /api/v1/logout rotates the user's jti (JTIMatcher),
      # which invalidates every token issued for that user, not only the one
      # used in this request; there is no "log out this device only" here.
      def respond_to_on_destroy(non_navigational_status: :no_content)
        head non_navigational_status
      end

      # Kept in exact sync with MeController#user_payload (Bloco 6E) — the
      # frontend stores whichever of these two responses it received last as
      # `session.user`, so a mismatched shape would make that value differ
      # depending on whether it came from login or from a /me refresh.
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
