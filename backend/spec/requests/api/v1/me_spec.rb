require "rails_helper"

RSpec.describe "GET /api/v1/me", type: :request do
  it "returns the current user's profile when authenticated" do
    user = create(:user, name: "Fran", role: "manager")
    token = jwt_for(user)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body["id"]).to eq(user.id)
    expect(body["email"]).to eq(user.email)
    expect(body["role"]).to eq("manager")
  end

  it "returns all_sectors and sector_ids" do
    cozinha = create(:sector, name: "Cozinha")
    confeitaria = create(:sector, name: "Confeitaria")
    user = create(:user, all_sectors: false)
    create(:user_sector, user: user, sector: cozinha)
    create(:user_sector, user: user, sector: confeitaria)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{jwt_for(user)}" }

    body = JSON.parse(response.body)
    expect(body["all_sectors"]).to be false
    expect(body["sector_ids"]).to contain_exactly(cozinha.id, confeitaria.id)
  end

  it "returns an empty sector_ids array and all_sectors=true for a user with unrestricted sector access" do
    user = create(:user, all_sectors: true)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{jwt_for(user)}" }

    body = JSON.parse(response.body)
    expect(body["all_sectors"]).to be true
    expect(body["sector_ids"]).to eq([])
  end

  it "does not expose a generic permissions list or full sector objects" do
    user = create(:user)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{jwt_for(user)}" }

    body = JSON.parse(response.body)
    expect(body).not_to have_key("permissions")
    expect(body).not_to have_key("sectors")
  end

  it "returns 401 without a token" do
    get "/api/v1/me"

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)["error"]).to be_present
  end

  it "returns 401 with a garbage/invalid token" do
    get "/api/v1/me", headers: { "Authorization" => "Bearer not-a-real-token" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 once the token has expired" do
    user = create(:user)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{expired_jwt_for(user)}" }

    expect(response).to have_http_status(:unauthorized)
  end
end
