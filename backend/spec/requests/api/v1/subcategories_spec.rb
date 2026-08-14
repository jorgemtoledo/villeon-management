require "rails_helper"

RSpec.describe "Api::V1::Subcategories", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/subcategories" do
    it "is reachable by admin, manager and operator" do
      create(:subcategory)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/subcategories", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "requires authentication" do
      get "/api/v1/subcategories"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns every subcategory by code, sorted, without pagination" do
      zebra = create(:subcategory, code: "ZEB")
      abacaxi = create(:subcategory, code: "ABA")

      get "/api/v1/subcategories", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["meta"]).to be_nil
      codes = body["data"].map { |s| s["code"] }
      expect(codes.index("ABA")).to be < codes.index("ZEB")
      expect(body["data"]).to include(
        { "id" => abacaxi.id, "code" => "ABA" },
        { "id" => zebra.id, "code" => "ZEB" }
      )
    end

    it "exposes only id and code — never an invented name/description" do
      create(:subcategory, code: "PRO")

      get "/api/v1/subcategories", headers: auth_headers(admin)

      expect(JSON.parse(response.body)["data"].first.keys).to contain_exactly("id", "code")
    end
  end
end
