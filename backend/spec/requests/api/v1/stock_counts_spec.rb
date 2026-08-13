require "rails_helper"

RSpec.describe "Api::V1::StockCounts", type: :request do
  let(:cozinha) { create(:sector) }
  let(:bar) { create(:sector) }
  let(:luiz) { create(:user, role: "operator", password: "password123") }
  let(:admin) { create(:user, role: "admin", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  before { create(:user_sector, user: luiz, sector: cozinha) }

  describe "POST /api/v1/products/:product_id/stock_counts" do
    it "registers a count and syncs the product's current_quantity" do
      product = create(:product, sector: cozinha)

      post "/api/v1/products/#{product.id}/stock_counts",
           params: { stock_count: { quantity: 12 } },
           headers: auth_headers(luiz)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(BigDecimal(body["quantity"])).to eq(BigDecimal("12"))
      expect(body["user"]["id"]).to eq(luiz.id)
      expect(product.reload.product_stock.current_quantity).to eq(BigDecimal("12"))
    end

    it "always attributes the count to the authenticated user, ignoring any user_id in the body" do
      product = create(:product, sector: cozinha)
      other = create(:user)

      post "/api/v1/products/#{product.id}/stock_counts",
           params: { stock_count: { quantity: 5, user_id: other.id } },
           headers: auth_headers(luiz)

      expect(JSON.parse(response.body)["user"]["id"]).to eq(luiz.id)
    end

    it "denies registering a count for a product in a sector the user doesn't have" do
      product = create(:product, sector: bar)

      post "/api/v1/products/#{product.id}/stock_counts",
           params: { stock_count: { quantity: 5 } },
           headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      product = create(:product)

      post "/api/v1/products/#{product.id}/stock_counts", params: { stock_count: { quantity: 5 } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a negative quantity with a validation error" do
      product = create(:product, sector: cozinha)

      post "/api/v1/products/#{product.id}/stock_counts",
           params: { stock_count: { quantity: -1 } },
           headers: auth_headers(luiz)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/stock_counts/:id" do
    it "updates the count and re-syncs current_quantity" do
      product = create(:product, sector: cozinha)
      count = create(:stock_count, product: product, user: luiz, quantity: 10)

      patch "/api/v1/stock_counts/#{count.id}",
            params: { stock_count: { quantity: 20 } },
            headers: auth_headers(luiz)

      expect(response).to have_http_status(:ok)
      expect(product.reload.product_stock.current_quantity).to eq(BigDecimal("20"))
    end

    it "denies updating a count belonging to a sector the user doesn't have" do
      product = create(:product, sector: bar)
      count = create(:stock_count, product: product)

      patch "/api/v1/stock_counts/#{count.id}",
            params: { stock_count: { quantity: 20 } },
            headers: auth_headers(luiz)

      expect(response).to have_http_status(:forbidden)
    end

    it "is reachable by admin regardless of sector" do
      product = create(:product, sector: bar)
      count = create(:stock_count, product: product)

      patch "/api/v1/stock_counts/#{count.id}",
            params: { stock_count: { quantity: 20 } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end
  end
end
