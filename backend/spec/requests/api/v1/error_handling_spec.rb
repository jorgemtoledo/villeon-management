require "rails_helper"

# Exercises the ApplicationController-level 401/403 JSON contract. No real
# authorized resource exists yet (Products/Suppliers/Purchases come in a
# later block), so this mounts a throwaway controller+route for the
# duration of this file only, then restores the real routes.rb.
class Api::V1::AuthzProbeController < Api::V1::BaseController
  def show
    authorize! :manage, :all
    head :ok
  end
end

RSpec.describe "API auth error handling (401/403 JSON contract)", type: :request do
  before do
    Rails.application.routes.draw do
      get "/api/v1/__authz_probe", to: "api/v1/authz_probe#show"
    end
  end

  after { Rails.application.reload_routes! }

  it "returns a JSON 401 when no token is sent" do
    get "/api/v1/__authz_probe"

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)["error"]).to be_present
  end

  it "returns a JSON 403 when authenticated but not authorized (CanCan::AccessDenied)" do
    user = create(:user, role: "operator", password: "password123")
    token = jwt_for(user)

    get "/api/v1/__authz_probe", headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body)["error"]).to be_present
  end

  it "allows the request through when authorized" do
    admin = create(:user, role: "admin", password: "password123")
    token = jwt_for(admin)

    get "/api/v1/__authz_probe", headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)
  end
end
