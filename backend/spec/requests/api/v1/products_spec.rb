require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/products" do
    it "is reachable by admin, manager and operator" do
      create(:product)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/products", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "requires authentication" do
      get "/api/v1/products"

      expect(response).to have_http_status(:unauthorized)
    end

    describe "pagination" do
      it "paginates with a default per_page and correct meta" do
        create_list(:product, 3)

        get "/api/v1/products", headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(3)
        expect(body["meta"]).to eq(
          { "page" => 1, "per_page" => 25, "total_pages" => 1, "total_count" => 3 }
        )
      end

      it "honors page and per_page" do
        create_list(:product, 5)

        get "/api/v1/products", params: { per_page: 2, page: 2 }, headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(2)
        expect(body["meta"]).to include("page" => 2, "per_page" => 2, "total_pages" => 3, "total_count" => 5)
      end

      it "clamps per_page to the maximum allowed" do
        create_list(:product, 3)

        get "/api/v1/products", params: { per_page: 999 }, headers: auth_headers(admin)

        expect(JSON.parse(response.body)["meta"]["per_page"]).to eq(100)
      end

      it "returns an empty page instead of an error when the requested page overflows" do
        create_list(:product, 2)

        get "/api/v1/products", params: { page: 50 }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["data"]).to eq([])
        expect(body["meta"]["total_count"]).to eq(2)
      end
    end

    describe "search (q)" do
      it "matches by name or code, case-insensitively" do
        matched_by_name = create(:product, name: "File Mignon", code: "COZ-001")
        matched_by_code = create(:product, name: "Outro produto", code: "BAR-999")
        create(:product, name: "Nada a ver", code: "XYZ-1")

        get "/api/v1/products", params: { q: "file" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matched_by_name.id)

        get "/api/v1/products", params: { q: "bar-999" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matched_by_code.id)
      end
    end

    describe "filters" do
      it "filters by sector_id" do
        bar = create(:sector)
        cozinha = create(:sector)
        in_bar = create(:product, sector: bar)
        create(:product, sector: cozinha)

        get "/api/v1/products", params: { sector_id: bar.id }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(in_bar.id)
      end

      it "filters by active status" do
        active_product = create(:product, active: true)
        inactive_product = create(:product, active: false)

        get "/api/v1/products", params: { active: "false" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to contain_exactly(inactive_product.id)

        get "/api/v1/products", params: { active: "true" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to contain_exactly(active_product.id)
      end

      it "returns both active and inactive when the filter is omitted" do
        create(:product, active: true)
        create(:product, active: false)

        get "/api/v1/products", headers: auth_headers(admin)

        expect(JSON.parse(response.body)["data"].size).to eq(2)
      end
    end

    describe "sorting" do
      it "sorts by the given column and direction" do
        create(:product, name: "Zebra", code: "Z1")
        create(:product, name: "Abacaxi", code: "A1")

        get "/api/v1/products", params: { sort: "name", order: "asc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["name"] }).to eq(%w[Abacaxi Zebra])

        get "/api/v1/products", params: { sort: "name", order: "desc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["name"] }).to eq(%w[Zebra Abacaxi])
      end

      it "falls back to sorting by name when an unknown/unsafe column is requested" do
        create(:product, name: "Zebra", code: "Z1")
        create(:product, name: "Abacaxi", code: "A1")

        get "/api/v1/products", params: { sort: "id; DROP TABLE products;--" }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"].map { |p| p["name"] }).to eq(%w[Abacaxi Zebra])
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    it "is reachable by all roles" do
      product = create(:product)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/products/#{product.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns 404 JSON for an unknown id" do
      get "/api/v1/products/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "POST /api/v1/products" do
    let(:sector) { create(:sector) }
    let(:purchase_unit) { create(:unit) }
    let(:stock_unit) { create(:unit) }
    let(:valid_params) do
      {
        product: {
          name: "File Mignon",
          code: "COZ-100",
          sector_id: sector.id,
          purchase_unit_id: purchase_unit.id,
          stock_unit_id: stock_unit.id,
          conversion_factor: 1
        }
      }
    end

    it "allows admin to create a product" do
      post "/api/v1/products", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["code"]).to eq("COZ-100")
      expect(body["active"]).to be true
    end

    it "creates a product without a category, since the real taxonomy isn't defined yet" do
      post "/api/v1/products", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["category"]).to be_nil
    end

    it "forbids manager from creating a product" do
      post "/api/v1/products", params: valid_params, headers: auth_headers(manager), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids operator from creating a product" do
      post "/api/v1/products", params: valid_params, headers: auth_headers(operator), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 JSON with validation details when invalid" do
      invalid_params = valid_params.deep_merge(product: { name: "" })

      post "/api/v1/products", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
    end

    it "returns 400 JSON when the product key is missing entirely" do
      # An empty body has nothing for Rails' automatic param wrapping to nest
      # under :product, so params.require(:product) genuinely raises here —
      # a body with unwrapped top-level attributes would get auto-wrapped
      # instead and fail validation (422), not this.
      post "/api/v1/products", params: {}, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "PATCH /api/v1/products/:id" do
    it "allows admin to update a product" do
      product = create(:product, name: "Nome antigo")

      patch "/api/v1/products/#{product.id}",
        params: { product: { name: "Nome novo" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Nome novo")
    end

    it "forbids manager and operator from updating" do
      product = create(:product)

      [ manager, operator ].each do |user|
        patch "/api/v1/products/#{product.id}",
          params: { product: { name: "X" } }, headers: auth_headers(user), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "ignores an active param — active only changes via activate/deactivate" do
      product = create(:product, active: true)

      patch "/api/v1/products/#{product.id}",
        params: { product: { active: false } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(product.reload.active).to be true
    end
  end

  describe "PATCH /api/v1/products/:id/activate" do
    it "allows admin to activate an inactive product" do
      product = create(:product, active: false)

      patch "/api/v1/products/#{product.id}/activate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(product.reload.active).to be true
    end

    it "forbids manager and operator" do
      product = create(:product, active: false)

      [ manager, operator ].each do |user|
        patch "/api/v1/products/#{product.id}/activate", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/products/:id/deactivate" do
    it "allows admin to deactivate an active product" do
      product = create(:product, active: true)

      patch "/api/v1/products/#{product.id}/deactivate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(product.reload.active).to be false
    end

    it "forbids manager and operator" do
      product = create(:product, active: true)

      [ manager, operator ].each do |user|
        patch "/api/v1/products/#{product.id}/deactivate", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
