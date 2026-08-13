require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    it "logs in with valid credentials and returns the JWT only in the Authorization header" do
      user = create(:user, password: "password123")

      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to match(/\ABearer .+/)

      body = JSON.parse(response.body)
      expect(body["user"]["email"]).to eq(user.email)
      expect(body).not_to have_key("token")
      expect(body["user"]).not_to have_key("token")
    end

    it "includes all_sectors and sector_ids, matching /me's contract" do
      sector = create(:sector)
      user = create(:user, password: "password123", all_sectors: false)
      create(:user_sector, user: user, sector: sector)

      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }

      body = JSON.parse(response.body)["user"]
      expect(body["all_sectors"]).to be false
      expect(body["sector_ids"]).to contain_exactly(sector.id)
    end

    it "rejects invalid credentials with 401 and issues no token" do
      create(:user, email: "user@villeon.example.com", password: "password123")

      post "/api/v1/login", params: { user: { email: "user@villeon.example.com", password: "wrong-password" } }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).to be_nil
      expect(JSON.parse(response.body)["error"]).to be_present
    end

    it "rejects an unknown email with 401" do
      post "/api/v1/login", params: { user: { email: "ghost@villeon.example.com", password: "whatever" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "requires authentication" do
      delete "/api/v1/logout"

      expect(response).to have_http_status(:unauthorized)
    end

    it "revokes the token so it can no longer be used" do
      user = create(:user, password: "password123")
      token = jwt_for(user)

      delete "/api/v1/logout", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:no_content)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "invalidates every token issued for the user (JTIMatcher), not only the one used to log out" do
      user = create(:user, password: "password123")
      token_from_device_a = jwt_for(user)
      token_from_device_b = jwt_for(user)

      delete "/api/v1/logout", headers: { "Authorization" => "Bearer #{token_from_device_a}" }

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{token_from_device_b}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
