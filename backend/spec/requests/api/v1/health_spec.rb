require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns ok when database and redis are reachable" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("ok")
      expect(body["checks"]).to eq({ "database" => true, "redis" => true })
    end
  end
end
