require "rails_helper"

RSpec.describe "Api::V1::Units", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/units" do
    it "is reachable by admin, manager and operator" do
      create(:unit)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/units", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "requires authentication" do
      get "/api/v1/units"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns every unit, sorted by name, without pagination" do
      zebra = create(:unit, name: "Zebra", abbreviation: "ZB")
      abacaxi = create(:unit, name: "Abacaxi", abbreviation: "AB")

      get "/api/v1/units", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["meta"]).to be_nil
      names = body["data"].map { |u| u["name"] }
      expect(names.index("Abacaxi")).to be < names.index("Zebra")
      expect(body["data"]).to include(
        { "id" => abacaxi.id, "name" => "Abacaxi", "abbreviation" => "AB" },
        { "id" => zebra.id, "name" => "Zebra", "abbreviation" => "ZB" }
      )
    end
  end
end
