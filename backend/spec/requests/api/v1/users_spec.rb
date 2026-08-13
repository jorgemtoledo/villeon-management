require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/users" do
    it "is reachable by admin" do
      create(:user)

      get "/api/v1/users", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end

    it "forbids manager and operator" do
      [ manager, operator ].each do |user|
        get "/api/v1/users", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "requires authentication" do
      get "/api/v1/users"

      expect(response).to have_http_status(:unauthorized)
    end

    it "never exposes encrypted_password, jti or reset_password_token" do
      create(:user)

      get "/api/v1/users", headers: auth_headers(admin)

      body = JSON.parse(response.body)["data"].first
      expect(body).not_to have_key("encrypted_password")
      expect(body).not_to have_key("password")
      expect(body).not_to have_key("password_confirmation")
      expect(body).not_to have_key("jti")
      expect(body).not_to have_key("reset_password_token")
    end

    describe "pagination" do
      it "paginates with a default per_page and correct meta" do
        create_list(:user, 3)

        get "/api/v1/users", headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["meta"]).to include("page" => 1, "per_page" => 25)
        expect(body["data"].size).to eq(body["meta"]["total_count"])
      end
    end

    describe "search (q)" do
      it "matches by name or email, case-insensitively" do
        matched = create(:user, name: "Luiz Operador")
        create(:user, name: "Nada a ver")

        get "/api/v1/users", params: { q: "luiz" }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |u| u["id"] }
        expect(ids).to include(matched.id)
      end
    end

    describe "filters" do
      it "filters by role" do
        op = create(:user, role: "operator")

        get "/api/v1/users", params: { role: "operator" }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |u| u["id"] }
        expect(ids).to include(op.id)
        expect(ids).not_to include(admin.id)
      end

      it "filters by active status" do
        inactive = create(:user, active: false)

        get "/api/v1/users", params: { active: "false" }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |u| u["id"] }
        expect(ids).to contain_exactly(inactive.id)
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    it "is reachable by admin and returns all_sectors/sector_ids" do
      sector = create(:sector)
      user = create(:user, all_sectors: false)
      create(:user_sector, user: user, sector: sector)

      get "/api/v1/users/#{user.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["all_sectors"]).to be false
      expect(body["sector_ids"]).to eq([ sector.id ])
    end

    it "forbids manager and operator" do
      user = create(:user)

      [ manager, operator ].each do |actor|
        get "/api/v1/users/#{user.id}", headers: auth_headers(actor)
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 404 JSON for an unknown id" do
      get "/api/v1/users/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/users" do
    let(:valid_params) do
      { user: { name: "Luiz", email: "luiz@villeon.example.com", role: "operator",
                password: "password123", password_confirmation: "password123", all_sectors: false } }
    end

    it "allows admin to create a user" do
      post "/api/v1/users", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Luiz")
      expect(body["role"]).to eq("operator")
      expect(body["active"]).to be true
    end

    it "forbids manager and operator from creating a user" do
      [ manager, operator ].each do |actor|
        post "/api/v1/users", params: valid_params, headers: auth_headers(actor), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "creates a user with specific sectors" do
      cozinha = create(:sector, name: "Cozinha")
      params = valid_params.deep_merge(user: { sector_ids: [ cozinha.id ] })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["sector_ids"]).to eq([ cozinha.id ])
    end

    it "creates a user with all_sectors=true and no sector_ids" do
      params = valid_params.deep_merge(user: { all_sectors: true })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["all_sectors"]).to be true
      expect(body["sector_ids"]).to eq([])
    end

    it "creates a user with all_sectors=false and sector_ids=[] (no sector access yet)" do
      params = valid_params.deep_merge(user: { all_sectors: false, sector_ids: [] })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["all_sectors"]).to be false
      expect(body["sector_ids"]).to eq([])
    end

    it "requires a password on create" do
      params = valid_params.deep_merge(user: { password: "", password_confirmation: "" })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a mismatched password confirmation" do
      params = valid_params.deep_merge(user: { password_confirmation: "different" })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
    end

    it "returns 422 for a duplicate email" do
      create(:user, email: "luiz@villeon.example.com")

      post "/api/v1/users", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an invalid role" do
      params = valid_params.deep_merge(user: { role: "superadmin" })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to include(match(/role/i))
    end

    it "returns 422 for a nonexistent sector id" do
      params = valid_params.deep_merge(user: { sector_ids: [ 999_999 ] })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to include(match(/setor/i))
    end

    it "never persists a duplicate UserSector row" do
      cozinha = create(:sector, name: "Cozinha")
      params = valid_params.deep_merge(user: { sector_ids: [ cozinha.id, cozinha.id ] })

      post "/api/v1/users", params: params, headers: auth_headers(admin), as: :json

      user_id = JSON.parse(response.body)["id"]
      expect(UserSector.where(user_id: user_id, sector_id: cozinha.id).count).to eq(1)
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "allows admin to update name/email" do
      user = create(:user, name: "Nome antigo")

      patch "/api/v1/users/#{user.id}", params: { user: { name: "Nome novo" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Nome novo")
    end

    it "allows admin to change role" do
      user = create(:user, role: "operator")

      patch "/api/v1/users/#{user.id}", params: { user: { role: "manager" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["role"]).to eq("manager")
    end

    it "allows admin to change sectors, replacing the previous set" do
      cozinha = create(:sector, name: "Cozinha")
      bar = create(:sector, name: "Bar")
      user = create(:user, all_sectors: false)
      create(:user_sector, user: user, sector: cozinha)

      patch "/api/v1/users/#{user.id}", params: { user: { sector_ids: [ bar.id ] } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["sector_ids"]).to eq([ bar.id ])
      expect(UserSector.where(user_id: user.id).count).to eq(1)
    end

    it "forbids manager and operator" do
      user = create(:user)

      [ manager, operator ].each do |actor|
        patch "/api/v1/users/#{user.id}", params: { user: { name: "X" } }, headers: auth_headers(actor), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "leaves the password unchanged when password fields are blank" do
      user = create(:user, password: "original123")
      original_digest = user.encrypted_password

      patch "/api/v1/users/#{user.id}",
        params: { user: { name: "Novo nome", password: "", password_confirmation: "" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.encrypted_password).to eq(original_digest)
    end

    it "changes the password when a new one is provided" do
      user = create(:user, password: "original123")
      original_digest = user.encrypted_password

      patch "/api/v1/users/#{user.id}",
        params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } },
        headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.encrypted_password).not_to eq(original_digest)
    end

    it "ignores an active param — active only changes via activate/deactivate" do
      user = create(:user, active: true)

      patch "/api/v1/users/#{user.id}", params: { user: { active: false } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.active).to be true
    end

    it "returns 404 for an unknown id" do
      patch "/api/v1/users/999999", params: { user: { name: "X" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end

    describe "last active admin protection" do
      it "blocks the sole admin from demoting themselves" do
        sole_admin = create(:user, role: "admin", active: true, password: "password123")

        patch "/api/v1/users/#{sole_admin.id}", params: { user: { role: "manager" } },
          headers: auth_headers(sole_admin), as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(sole_admin.reload.role).to eq("admin")
      end

      it "allows demoting an admin when another active admin exists" do
        sole_admin = create(:user, role: "admin", active: true)
        other_admin = create(:user, role: "admin", active: true, password: "password123")

        patch "/api/v1/users/#{sole_admin.id}", params: { user: { role: "manager" } },
          headers: auth_headers(other_admin), as: :json

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /api/v1/users/:id/activate" do
    it "allows admin to activate an inactive user" do
      user = create(:user, active: false)

      patch "/api/v1/users/#{user.id}/activate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(user.reload.active).to be true
    end

    it "forbids manager and operator" do
      user = create(:user, active: false)

      [ manager, operator ].each do |actor|
        patch "/api/v1/users/#{user.id}/activate", headers: auth_headers(actor)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/users/:id/deactivate" do
    it "allows admin to deactivate an active user" do
      user = create(:user, active: true)

      patch "/api/v1/users/#{user.id}/deactivate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(user.reload.active).to be false
    end

    it "forbids manager and operator" do
      user = create(:user, active: true)

      [ manager, operator ].each do |actor|
        patch "/api/v1/users/#{user.id}/deactivate", headers: auth_headers(actor)
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "blocks deactivating the sole active admin" do
      sole_admin = create(:user, role: "admin", active: true, password: "password123")

      patch "/api/v1/users/#{sole_admin.id}/deactivate", headers: auth_headers(sole_admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(sole_admin.reload.active).to be true
    end

    it "immediately blocks the deactivated user's already-issued JWT from further use" do
      user = create(:user, active: true, password: "password123")
      token = jwt_for(user)

      patch "/api/v1/users/#{user.id}/deactivate", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "login of a deactivated user" do
    it "fails with 401" do
      create(:user, email: "inativo@villeon.example.com", password: "password123", active: false)

      post "/api/v1/login", params: { user: { email: "inativo@villeon.example.com", password: "password123" } }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).to be_nil
    end
  end
end
