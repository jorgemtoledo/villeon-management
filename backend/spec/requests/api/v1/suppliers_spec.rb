require "rails_helper"

RSpec.describe "Api::V1::Suppliers", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/suppliers" do
    it "is reachable by admin, manager and operator" do
      create(:supplier)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/suppliers", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "requires authentication" do
      get "/api/v1/suppliers"

      expect(response).to have_http_status(:unauthorized)
    end

    describe "pagination" do
      it "paginates with a default per_page and correct meta" do
        create_list(:supplier, 3)

        get "/api/v1/suppliers", headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(3)
        expect(body["meta"]).to eq(
          { "page" => 1, "per_page" => 25, "total_pages" => 1, "total_count" => 3 }
        )
      end

      it "honors page and per_page" do
        create_list(:supplier, 5)

        get "/api/v1/suppliers", params: { per_page: 2, page: 2 }, headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(2)
        expect(body["meta"]).to include("page" => 2, "per_page" => 2, "total_pages" => 3, "total_count" => 5)
      end

      it "clamps per_page to the maximum allowed" do
        create_list(:supplier, 3)

        get "/api/v1/suppliers", params: { per_page: 999 }, headers: auth_headers(admin)

        expect(JSON.parse(response.body)["meta"]["per_page"]).to eq(100)
      end

      it "returns an empty page instead of an error when the requested page overflows" do
        create_list(:supplier, 2)

        get "/api/v1/suppliers", params: { page: 50 }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["data"]).to eq([])
        expect(body["meta"]["total_count"]).to eq(2)
      end
    end

    describe "search (q)" do
      it "matches by name or cnpj, case-insensitively" do
        matched_by_name = create(:supplier, name: "Distribuidora ABC")
        matched_by_cnpj = create(:supplier, name: "Outro", cnpj: "11222333000181")
        create(:supplier, name: "Nada a ver")

        get "/api/v1/suppliers", params: { q: "distribuidora" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |s| s["id"] }
        expect(ids).to contain_exactly(matched_by_name.id)

        get "/api/v1/suppliers", params: { q: "11222333" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |s| s["id"] }
        expect(ids).to contain_exactly(matched_by_cnpj.id)
      end
    end

    describe "filters" do
      it "filters by active status" do
        active_supplier = create(:supplier, active: true)
        inactive_supplier = create(:supplier, active: false)

        get "/api/v1/suppliers", params: { active: "false" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |s| s["id"] }).to contain_exactly(inactive_supplier.id)

        get "/api/v1/suppliers", params: { active: "true" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |s| s["id"] }).to contain_exactly(active_supplier.id)
      end

      it "returns both active and inactive when the filter is omitted" do
        create(:supplier, active: true)
        create(:supplier, active: false)

        get "/api/v1/suppliers", headers: auth_headers(admin)

        expect(JSON.parse(response.body)["data"].size).to eq(2)
      end
    end

    describe "sorting" do
      it "sorts by the given column and direction" do
        create(:supplier, name: "Zebra Ltda")
        create(:supplier, name: "Abacaxi Ltda")

        get "/api/v1/suppliers", params: { sort: "name", order: "asc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |s| s["name"] }).to eq([ "Abacaxi Ltda", "Zebra Ltda" ])

        get "/api/v1/suppliers", params: { sort: "name", order: "desc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |s| s["name"] }).to eq([ "Zebra Ltda", "Abacaxi Ltda" ])
      end

      it "falls back to sorting by name when an unknown/unsafe column is requested" do
        create(:supplier, name: "Zebra Ltda")
        create(:supplier, name: "Abacaxi Ltda")

        get "/api/v1/suppliers", params: { sort: "id; DROP TABLE suppliers;--" }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"].map { |s| s["name"] }).to eq([ "Abacaxi Ltda", "Zebra Ltda" ])
      end
    end

    it "includes products_count without N+1, matching the real linked product count" do
      supplier_with_products = create(:supplier)
      product_a = create(:product)
      product_b = create(:product)
      create(:product_supplier, supplier: supplier_with_products, product: product_a)
      create(:product_supplier, supplier: supplier_with_products, product: product_b)
      create(:supplier)

      get "/api/v1/suppliers", headers: auth_headers(admin)

      counts = JSON.parse(response.body)["data"].to_h { |s| [ s["id"], s["products_count"] ] }
      expect(counts[supplier_with_products.id]).to eq(2)
    end
  end

  describe "GET /api/v1/suppliers/:id" do
    it "is reachable by all roles and includes products_count" do
      supplier = create(:supplier)
      create(:product_supplier, supplier: supplier, product: create(:product))

      [ admin, manager, operator ].each do |user|
        get "/api/v1/suppliers/#{supplier.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end

      expect(JSON.parse(response.body)["products_count"]).to eq(1)
    end

    it "returns 404 JSON for an unknown id" do
      get "/api/v1/suppliers/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "GET /api/v1/suppliers/:id/products" do
    it "is reachable by all roles and lists linked products with pivot data" do
      supplier = create(:supplier)
      product = create(:product, name: "Abacaxi")
      create(:product_supplier,
        supplier: supplier, product: product, preferred: true, supplier_product_code: "AB-1", notes: "nota")

      [ admin, manager, operator ].each do |user|
        get "/api/v1/suppliers/#{supplier.id}/products", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end

      body = JSON.parse(response.body)
      expect(body["meta"]).to include("total_count" => 1)
      item = body["data"].first
      expect(item).to include(
        "id" => product.id,
        "name" => "Abacaxi",
        "supplier_product_code" => "AB-1",
        "preferred" => true,
        "notes" => "nota"
      )
    end

    it "returns an empty list for a supplier without linked products" do
      supplier = create(:supplier)

      get "/api/v1/suppliers/#{supplier.id}/products", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["data"]).to eq([])
      expect(body["meta"]["total_count"]).to eq(0)
    end

    it "returns 404 JSON for an unknown supplier id" do
      get "/api/v1/suppliers/999999/products", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/suppliers" do
    let(:valid_params) { { supplier: { name: "Distribuidora ABC", cnpj: "11.222.333/0001-81" } } }

    it "allows admin to create a supplier and normalizes the cnpj" do
      post "/api/v1/suppliers", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Distribuidora ABC")
      expect(body["cnpj"]).to eq("11222333000181")
      expect(body["active"]).to be true
      expect(body["products_count"]).to eq(0)
    end

    it "creates a supplier without a cnpj" do
      post "/api/v1/suppliers", params: { supplier: { name: "Sem CNPJ" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["cnpj"]).to be_nil
    end

    it "forbids manager from creating a supplier" do
      post "/api/v1/suppliers", params: valid_params, headers: auth_headers(manager), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids operator from creating a supplier" do
      post "/api/v1/suppliers", params: valid_params, headers: auth_headers(operator), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 JSON with validation details for a blank name" do
      post "/api/v1/suppliers", params: { supplier: { name: "" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
    end

    it "returns 422 JSON for a cnpj with an invalid check digit" do
      post "/api/v1/suppliers",
        params: { supplier: { name: "X", cnpj: "11222333000180" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
    end

    it "returns 400 JSON when the supplier key is missing entirely" do
      post "/api/v1/suppliers", params: {}, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "PATCH /api/v1/suppliers/:id" do
    it "allows admin to update a supplier" do
      supplier = create(:supplier, name: "Nome antigo")

      patch "/api/v1/suppliers/#{supplier.id}",
        params: { supplier: { name: "Nome novo" } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Nome novo")
    end

    it "forbids manager and operator from updating" do
      supplier = create(:supplier)

      [ manager, operator ].each do |user|
        patch "/api/v1/suppliers/#{supplier.id}",
          params: { supplier: { name: "X" } }, headers: auth_headers(user), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "ignores an active param — active only changes via activate/deactivate" do
      supplier = create(:supplier, active: true)

      patch "/api/v1/suppliers/#{supplier.id}",
        params: { supplier: { active: false } }, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(supplier.reload.active).to be true
    end
  end

  describe "PATCH /api/v1/suppliers/:id/activate" do
    it "allows admin to activate an inactive supplier" do
      supplier = create(:supplier, active: false)

      patch "/api/v1/suppliers/#{supplier.id}/activate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(supplier.reload.active).to be true
    end

    it "forbids manager and operator" do
      supplier = create(:supplier, active: false)

      [ manager, operator ].each do |user|
        patch "/api/v1/suppliers/#{supplier.id}/activate", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/suppliers/:id/deactivate" do
    it "allows admin to deactivate an active supplier" do
      supplier = create(:supplier, active: true)

      patch "/api/v1/suppliers/#{supplier.id}/deactivate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(supplier.reload.active).to be false
    end

    it "forbids manager and operator" do
      supplier = create(:supplier, active: true)

      [ manager, operator ].each do |user|
        patch "/api/v1/suppliers/#{supplier.id}/deactivate", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
