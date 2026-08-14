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

      it "filters by subcategory_id" do
        pro = create(:subcategory, code: "PRO")
        acu = create(:subcategory, code: "ACU")
        in_pro = create(:product, subcategory: pro)
        create(:product, subcategory: acu)
        create(:product, subcategory: nil)

        get "/api/v1/products", params: { subcategory_id: pro.id }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(in_pro.id)
      end

      it "combines subcategory_id with sector_id and active" do
        cozinha = create(:sector)
        bar = create(:sector)
        pro = create(:subcategory, code: "PRO")
        matching = create(:product, sector: cozinha, subcategory: pro, active: true)
        create(:product, sector: bar, subcategory: pro, active: true) # wrong sector
        create(:product, sector: cozinha, subcategory: pro, active: false) # inactive
        create(:product, sector: cozinha, subcategory: nil, active: true) # no subcategory

        get "/api/v1/products",
            params: { sector_id: cozinha.id, subcategory_id: pro.id, active: "true" },
            headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matching.id)
      end

      it "combines subcategory_id with search by name/code" do
        pro = create(:subcategory, code: "PRO")
        matching = create(:product, name: "Cupim bovino", code: "COZ-777", subcategory: pro)
        create(:product, name: "Cupim de outro tipo", code: "COZ-778", subcategory: nil)

        get "/api/v1/products", params: { q: "Cupim", subcategory_id: pro.id }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matching.id)
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

  describe "last_purchase_price / last_purchase_date (Bloco 6H.4)" do
    def counts_queries_on(table)
      count = 0
      subscriber = lambda do |*, payload|
        count += 1 if payload[:sql].include?(table) && payload[:sql] =~ /\ASELECT/i
      end
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
      count
    end

    it "returns null for a product that was never purchased" do
      product = create(:product)

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["last_purchase_price"]).to be_nil
      expect(body["last_purchase_date"]).to be_nil
    end

    it "returns the price/date of the single purchase for a product with one" do
      product = create(:product)
      purchase = create(:purchase, purchased_at: Date.new(2026, 3, 1))
      create(:purchase_item, product: product, purchase: purchase, unit_price: 12.5)

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(BigDecimal(body["last_purchase_price"])).to eq(BigDecimal("12.5"))
      expect(Date.parse(body["last_purchase_date"])).to eq(Date.new(2026, 3, 1))
    end

    it "picks the most recent purchase (by date) when there are several on different dates" do
      product = create(:product)
      old_purchase = create(:purchase, purchased_at: Date.new(2026, 1, 1))
      new_purchase = create(:purchase, purchased_at: Date.new(2026, 6, 1))
      create(:purchase_item, product: product, purchase: old_purchase, unit_price: 10)
      create(:purchase_item, product: product, purchase: new_purchase, unit_price: 20)

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(BigDecimal(body["last_purchase_price"])).to eq(BigDecimal("20"))
      expect(Date.parse(body["last_purchase_date"])).to eq(Date.new(2026, 6, 1))
    end

    it "picks a real row among several purchases on the same date (date alone doesn't distinguish them)" do
      product = create(:product)
      purchase = create(:purchase, purchased_at: Date.new(2026, 5, 10))
      create(:purchase_item, product: product, purchase: purchase, unit_price: 7, quantity: 1)
      create(:purchase_item, product: product, purchase: purchase, unit_price: 7, quantity: 2)

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(Date.parse(body["last_purchase_date"])).to eq(Date.new(2026, 5, 10))
      expect(BigDecimal(body["last_purchase_price"])).to eq(BigDecimal("7"))
    end

    it "breaks a same-date tie with different prices by id DESC, matching the source spreadsheet's own tiebreak" do
      product = create(:product)
      purchase = create(:purchase, purchased_at: Date.new(2026, 5, 10))
      first_item = create(:purchase_item, product: product, purchase: purchase, unit_price: 7)
      second_item = create(:purchase_item, product: product, purchase: purchase, unit_price: 9)
      expect(second_item.id).to be > first_item.id

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      # The higher-id item (9) must win, never the lower-id one (7) and never
      # an arbitrary pick — this is the exact scenario (84 real cases in the
      # source data) purchased_at alone can't resolve.
      expect(BigDecimal(JSON.parse(response.body)["last_purchase_price"])).to eq(BigDecimal("9"))
    end

    it "confirms id DESC — not price, not quantity — is what decides the tie" do
      product = create(:product)
      purchase = create(:purchase, purchased_at: Date.new(2026, 5, 10))
      create(:purchase_item, product: product, purchase: purchase, unit_price: 99) # highest price, created first
      last_item = create(:purchase_item, product: product, purchase: purchase, unit_price: 1) # lowest price, created last

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      expect(BigDecimal(JSON.parse(response.body)["last_purchase_price"])).to eq(last_item.unit_price)
    end

    it "always returns price and date from the same winning PurchaseItem/Purchase, never mixed" do
      product = create(:product)
      early = create(:purchase, purchased_at: Date.new(2026, 1, 1))
      late = create(:purchase, purchased_at: Date.new(2026, 5, 10))
      create(:purchase_item, product: product, purchase: early, unit_price: 50)
      winning_item = create(:purchase_item, product: product, purchase: late, unit_price: 30)

      get "/api/v1/products/#{product.id}", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(BigDecimal(body["last_purchase_price"])).to eq(winning_item.unit_price)
      expect(Date.parse(body["last_purchase_date"])).to eq(winning_item.purchase.purchased_at.to_date)
    end

    it "runs exactly one query against purchase_items for the whole product listing, regardless of page size" do
      products = create_list(:product, 5)
      purchase = create(:purchase, purchased_at: Date.new(2026, 5, 10))
      products.each { |p| create(:purchase_item, product: p, purchase: purchase, unit_price: 10) }

      query_count = counts_queries_on("purchase_items") do
        get "/api/v1/products", headers: auth_headers(admin)
      end

      expect(response).to have_http_status(:ok)
      expect(query_count).to eq(1)
      returned = JSON.parse(response.body)["data"]
      expect(returned.count { |p| p["last_purchase_price"].present? }).to eq(5)
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

    it "creates a product with a subcategory and exposes it by code, not an invented name" do
      subcategory = create(:subcategory, code: "PRO")
      params = valid_params.deep_merge(product: { subcategory_id: subcategory.id })

      post "/api/v1/products", params: params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["subcategory"]).to eq({ "id" => subcategory.id, "code" => "PRO" })
    end

    it "creates a product without a subcategory when none is given" do
      post "/api/v1/products", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["subcategory"]).to be_nil
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
