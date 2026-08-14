require "rails_helper"

RSpec.describe "Api::V1::ProductStocks", type: :request do
  let(:cozinha) { create(:sector) }
  let(:bar) { create(:sector) }
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:fran) { create(:user, role: "manager", password: "password123", all_sectors: true) }
  let(:luiz) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  before { create(:user_sector, user: luiz, sector: cozinha) }

  describe "GET /api/v1/products/:product_id/stock" do
    it "returns nao_contado for a product that was never counted" do
      product = create(:product, sector: cozinha)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(luiz)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("nao_contado")
      expect(body["current_quantity"]).to be_nil
      expect(body["replenishment_quantity"]).to be_nil
    end

    it "returns computed replenishment/purchase/status for a counted product below minimum" do
      product = create(:product, sector: cozinha, conversion_factor: 1)
      create(:stock_count, product: product, quantity: 2)
      product.product_stock.update!(minimum_quantity: 5, ideal_quantity: 10)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(luiz)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("comprar")
      expect(BigDecimal(body["replenishment_quantity"])).to eq(BigDecimal("8"))
      expect(body["purchase_quantity"]).to eq(8)
    end

    it "is reachable by admin and by all_sectors users for any sector" do
      product = create(:product, sector: bar)

      [ admin, fran ].each do |user|
        get "/api/v1/products/#{product.id}/stock", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "allows access to a user's own sector" do
      product = create(:product, sector: cozinha)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(luiz)

      expect(response).to have_http_status(:ok)
    end

    it "denies access to a sector the user doesn't have, even by guessing the product id" do
      product = create(:product, sector: bar)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies a user with no sector at all and no all_sectors flag" do
      no_sector_user = create(:user, role: "operator", password: "password123")
      product = create(:product, sector: cozinha)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(no_sector_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "shows inativo status for a deactivated product, even if below minimum" do
      product = create(:product, sector: cozinha, active: false, conversion_factor: 1)
      create(:stock_count, product: product, quantity: 0)
      product.product_stock.update!(minimum_quantity: 5, ideal_quantity: 10)

      get "/api/v1/products/#{product.id}/stock", headers: auth_headers(luiz)

      expect(JSON.parse(response.body)["status"]).to eq("inativo")
    end

    it "requires authentication" do
      product = create(:product)

      get "/api/v1/products/#{product.id}/stock"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/products/:product_id/stock (Bloco 6G Parte 2 — structural config)" do
    it "lets admin configure minimum/ideal for a product never counted before" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock",
            params: { product_stock: { minimum_quantity: 5, ideal_quantity: 20 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(BigDecimal(body["minimum_quantity"])).to eq(BigDecimal("5"))
      expect(BigDecimal(body["ideal_quantity"])).to eq(BigDecimal("20"))
      # still "nao_contado": configuring targets isn't the same as counting the shelf.
      expect(body["status"]).to eq("nao_contado")
      expect(body["current_quantity"]).to be_nil
    end

    it "lets admin update minimum/ideal for an already-counted product, without touching current_quantity" do
      product = create(:product, sector: cozinha, conversion_factor: 1)
      create(:stock_count, product: product, quantity: 3)

      patch "/api/v1/products/#{product.id}/stock",
            params: { product_stock: { minimum_quantity: 5, ideal_quantity: 20 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(BigDecimal(body["current_quantity"])).to eq(BigDecimal("3"))
      expect(body["status"]).to eq("comprar")
    end

    it "denies manager and operator, regardless of sector access" do
      product = create(:product, sector: cozinha)
      fran = create(:user, role: "manager", password: "password123", all_sectors: true)

      [ luiz, fran ].each do |user|
        patch "/api/v1/products/#{product.id}/stock",
              params: { product_stock: { minimum_quantity: 5, ideal_quantity: 20 } },
              headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "rejects a negative minimum with 422" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock",
            params: { product_stock: { minimum_quantity: -1, ideal_quantity: 20 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a negative ideal with 422" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock",
            params: { product_stock: { minimum_quantity: 5, ideal_quantity: -1 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects ideal below minimum with 422" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock",
            params: { product_stock: { minimum_quantity: 10, ideal_quantity: 5 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to include(a_string_matching(/menor que o estoque mínimo/))
    end

    it "returns 404 for a product that doesn't exist" do
      patch "/api/v1/products/999999/stock",
            params: { product_stock: { minimum_quantity: 5, ideal_quantity: 20 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      product = create(:product)

      patch "/api/v1/products/#{product.id}/stock", params: { product_stock: { minimum_quantity: 5, ideal_quantity: 20 } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/products/:product_id/stock/priority (Bloco 6G Parte 4)" do
    it "lets admin configure priority/needs_advance_order for the first time" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical", needs_advance_order: true } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["priority"]).to eq("critical")
      expect(body["needs_advance_order"]).to eq(true)
    end

    it "lets manager configure it, in any sector, without needing all_sectors" do
      manager_no_all_sectors = create(:user, role: "manager", password: "password123")
      product = create(:product, sector: bar)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "normal", needs_advance_order: false } },
            headers: auth_headers(manager_no_all_sectors)

      expect(response).to have_http_status(:ok)
    end

    it "lets the sector-authorized responsible configure it the first time" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "low", needs_advance_order: false } },
            headers: auth_headers(luiz)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["priority"]).to eq("low")
      expect(body["needs_advance_order"]).to eq(false)
    end

    it "denies a responsible from the wrong sector" do
      product = create(:product, sector: bar)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical" } },
            headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies the responsible from changing it once it's already been set" do
      product = create(:product, sector: cozinha)
      product.create_product_stock!(priority: "normal", needs_advance_order: false)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical" } },
            headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
      expect(product.product_stock.reload.priority).to eq("normal")
    end

    it "lets manager override an already-set value" do
      product = create(:product, sector: cozinha)
      product.create_product_stock!(priority: "low", needs_advance_order: false)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical", needs_advance_order: true } },
            headers: auth_headers(fran)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["priority"]).to eq("critical")
      expect(body["needs_advance_order"]).to eq(true)
    end

    it "lets admin override an already-set value" do
      product = create(:product, sector: cozinha)
      product.create_product_stock!(priority: "low", needs_advance_order: false)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "normal" } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end

    it "denies a user with no sector at all and no all_sectors flag" do
      no_sector_user = create(:user, role: "operator", password: "password123")
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical" } },
            headers: auth_headers(no_sector_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "lets an all_sectors operator configure it in any sector" do
      all_sectors_operator = create(:user, role: "operator", password: "password123", all_sectors: true)
      product = create(:product, sector: bar)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "normal" } },
            headers: auth_headers(all_sectors_operator)

      expect(response).to have_http_status(:ok)
    end

    it "rejects an invalid priority value with 422" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "urgent" } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "accepts true and false for needs_advance_order" do
      product_a = create(:product, sector: cozinha)
      patch "/api/v1/products/#{product_a.id}/stock/priority",
            params: { product_stock: { needs_advance_order: true } },
            headers: auth_headers(luiz)
      expect(JSON.parse(response.body)["needs_advance_order"]).to eq(true)

      product_b = create(:product, sector: cozinha)
      patch "/api/v1/products/#{product_b.id}/stock/priority",
            params: { product_stock: { needs_advance_order: false } },
            headers: auth_headers(luiz)
      expect(JSON.parse(response.body)["needs_advance_order"]).to eq(false)
    end

    it "leaves the field not sent as nil (null continues to be allowed)" do
      product = create(:product, sector: cozinha)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical" } },
            headers: auth_headers(luiz)

      body = JSON.parse(response.body)
      expect(body["priority"]).to eq("critical")
      expect(body["needs_advance_order"]).to be_nil
    end

    it "never touches StockCount" do
      product = create(:product, sector: cozinha, conversion_factor: 1)
      count = create(:stock_count, product: product, quantity: 2)
      product.product_stock.update!(minimum_quantity: 5, ideal_quantity: 10)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical", needs_advance_order: true } },
            headers: auth_headers(luiz)

      expect(count.reload.quantity).to eq(BigDecimal("2"))
      expect(StockCount.where(product: product).count).to eq(1)
    end

    it "never changes replenishment/purchase/status" do
      product = create(:product, sector: cozinha, conversion_factor: 1)
      create(:stock_count, product: product, quantity: 2)
      product.product_stock.update!(minimum_quantity: 5, ideal_quantity: 10)

      patch "/api/v1/products/#{product.id}/stock/priority",
            params: { product_stock: { priority: "critical", needs_advance_order: true } },
            headers: auth_headers(luiz)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("comprar")
      expect(BigDecimal(body["replenishment_quantity"])).to eq(BigDecimal("8"))
      expect(body["purchase_quantity"]).to eq(8)
    end

    it "returns 404 for a product that doesn't exist" do
      patch "/api/v1/products/999999/stock/priority",
            params: { product_stock: { priority: "critical" } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      product = create(:product)

      patch "/api/v1/products/#{product.id}/stock/priority", params: { product_stock: { priority: "critical" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/product_stocks" do
    it "defaults to the current user's own sectors" do
      in_sector = create(:product, sector: cozinha)
      create(:product_stock, product: in_sector)
      outside_sector = create(:product, sector: bar)
      create(:product_stock, product: outside_sector)

      get "/api/v1/product_stocks", headers: auth_headers(luiz)

      ids = JSON.parse(response.body)["data"].map { |row| row["product"]["id"] }
      expect(ids).to contain_exactly(in_sector.id)
    end

    it "lets an all_sectors user see every sector, or filter to just one" do
      create(:product, sector: cozinha)
      create(:product, sector: bar)

      get "/api/v1/product_stocks", headers: auth_headers(fran)
      expect(JSON.parse(response.body)["data"].size).to eq(2)

      get "/api/v1/product_stocks", params: { sector_id: bar.id }, headers: auth_headers(fran)
      expect(JSON.parse(response.body)["data"].size).to eq(1)
    end

    it "rejects a sector_id the user isn't authorized for, instead of silently filtering it out" do
      get "/api/v1/product_stocks", params: { sector_id: bar.id }, headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden (not an empty list) for a user with no sector and not all_sectors" do
      no_sector_user = create(:user, role: "operator", password: "password123")

      get "/api/v1/product_stocks", headers: auth_headers(no_sector_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
