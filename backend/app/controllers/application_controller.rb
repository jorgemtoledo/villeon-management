class ApplicationController < ActionController::API
  include Pagy::Backend

  # Protected by default; controllers/actions that must stay public (e.g.
  # health checks, login) opt out explicitly with skip_before_action.
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Pagy::OverflowError, with: :render_page_overflow

  private

  def render_forbidden
    render json: { error: "Você não tem permissão para executar esta ação." }, status: :forbidden
  end

  def render_not_found
    render json: { error: "Registro não encontrado." }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  # A page beyond the last available one isn't a client error worth a 4xx —
  # same intent as "no results", just answered through pagination instead
  # of a filter.
  def render_page_overflow(exception)
    render json: { data: [], meta: pagination_meta(exception.pagy) }, status: :ok
  end

  def pagination_meta(pagy)
    {
      page: pagy.page,
      per_page: pagy.limit,
      total_pages: pagy.last,
      total_count: pagy.count
    }
  end
end
