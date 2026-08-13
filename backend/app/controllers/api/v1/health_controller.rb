module Api
  module V1
    # App-level health check: unlike the infra-level GET /up (no dependencies),
    # this confirms the services docker-compose wires together are actually reachable.
    class HealthController < BaseController
      # Infra/load balancers hit this without a token — must stay public.
      skip_before_action :authenticate_user!

      def show
        checks = { database: database_check, redis: redis_check }
        status = checks.values.all? { |ok| ok } ? :ok : :service_unavailable

        render json: {
          status: status == :ok ? "ok" : "error",
          checks: checks,
          timestamp: Time.current.iso8601
        }, status: status
      end

      private

      def database_check
        # #active? alone can report false on a lazily-established connection that
        # was never queried yet, so force an actual round-trip to the database.
        ActiveRecord::Base.connection.select_value("SELECT 1") == 1
      rescue StandardError
        false
      end

      def redis_check
        Sidekiq.redis(&:ping) == "PONG"
      rescue StandardError
        false
      end
    end
  end
end
