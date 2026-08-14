require "rails_helper"

RSpec.describe "Api::V1::StockAuditEntries", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/stock_audit_entries" do
    it "is reachable by admin and manager" do
      create(:stock_audit_entry)

      [ admin, manager ].each do |user|
        get "/api/v1/stock_audit_entries", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns 403 for operator" do
      get "/api/v1/stock_audit_entries", headers: auth_headers(operator)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/stock_audit_entries"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an empty list when there is no history yet" do
      get "/api/v1/stock_audit_entries", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["data"]).to eq([])
    end

    it "orders by created_at descending (most recent first)" do
      product = create(:product)
      older = create(:stock_audit_entry, product: product, created_at: 2.days.ago)
      newer = create(:stock_audit_entry, product: product, created_at: 1.hour.ago)

      get "/api/v1/stock_audit_entries", headers: auth_headers(admin)

      ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
      expect(ids).to eq([ newer.id, older.id ])
    end

    it "exposes product, user, field, previous/new value and created_at" do
      product = create(:product, name: "Abacaxi", code: "COZ-001")
      user = create(:user, name: "Luiz")
      entry = create(:stock_audit_entry, product: product, user: user, field: "current_quantity",
                                          previous_value: "12", new_value: "5")

      get "/api/v1/stock_audit_entries", headers: auth_headers(admin)

      row = JSON.parse(response.body)["data"].first
      expect(row).to include(
        "id" => entry.id,
        "field" => "current_quantity",
        "previous_value" => "12",
        "new_value" => "5"
      )
      expect(row["product"]).to eq({ "id" => product.id, "name" => "Abacaxi", "code" => "COZ-001" })
      expect(row["user"]).to eq({ "id" => user.id, "name" => "Luiz" })
    end

    describe "filters" do
      it "filters by user_id" do
        matching = create(:stock_audit_entry)
        create(:stock_audit_entry)

        get "/api/v1/stock_audit_entries", params: { user_id: matching.user_id }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
        expect(ids).to contain_exactly(matching.id)
      end

      it "filters by field (tipo de alteração)" do
        priority_entry = create(:stock_audit_entry, field: "priority", previous_value: nil, new_value: "critical")
        create(:stock_audit_entry, field: "current_quantity")

        get "/api/v1/stock_audit_entries", params: { field: "priority" }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
        expect(ids).to contain_exactly(priority_entry.id)
      end

      it "filters by product name or code (q)" do
        matching = create(:stock_audit_entry, product: create(:product, name: "Abacaxi", code: "COZ-777"))
        create(:stock_audit_entry, product: create(:product, name: "Outro produto", code: "COZ-778"))

        get "/api/v1/stock_audit_entries", params: { q: "Abacaxi" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |e| e["id"] }).to contain_exactly(matching.id)

        get "/api/v1/stock_audit_entries", params: { q: "COZ-777" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |e| e["id"] }).to contain_exactly(matching.id)
      end

      it "filters by período (date_from/date_to)" do
        in_range = create(:stock_audit_entry, created_at: Date.new(2026, 8, 14).noon)
        create(:stock_audit_entry, created_at: Date.new(2026, 8, 1).noon)
        create(:stock_audit_entry, created_at: Date.new(2026, 8, 20).noon)

        get "/api/v1/stock_audit_entries",
            params: { date_from: "2026-08-10", date_to: "2026-08-16" },
            headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
        expect(ids).to contain_exactly(in_range.id)
      end

      it "combines filters (product + field + período)" do
        product = create(:product, name: "Abacaxi", code: "COZ-777")
        matching = create(:stock_audit_entry, product: product, field: "priority",
                                                previous_value: nil, new_value: "critical",
                                                created_at: Date.new(2026, 8, 14).noon)
        create(:stock_audit_entry, product: product, field: "current_quantity",
                                     created_at: Date.new(2026, 8, 14).noon)
        create(:stock_audit_entry, product: create(:product, name: "Outro", code: "X-1"), field: "priority",
                                     previous_value: nil, new_value: "normal",
                                     created_at: Date.new(2026, 8, 14).noon)

        get "/api/v1/stock_audit_entries",
            params: { q: "Abacaxi", field: "priority", date_from: "2026-08-10", date_to: "2026-08-16" },
            headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
        expect(ids).to contain_exactly(matching.id)
      end
    end
  end

  describe "GET /api/v1/products/:product_id/stock_audit_entries" do
    it "returns only that product's entries, most recent first" do
      product = create(:product)
      other = create(:product)
      newer = create(:stock_audit_entry, product: product, created_at: 1.hour.ago)
      older = create(:stock_audit_entry, product: product, created_at: 1.day.ago)
      create(:stock_audit_entry, product: other)

      get "/api/v1/products/#{product.id}/stock_audit_entries", headers: auth_headers(manager)

      ids = JSON.parse(response.body)["data"].map { |e| e["id"] }
      expect(ids).to eq([ newer.id, older.id ])
    end

    it "returns an empty list for a product with no history" do
      product = create(:product)

      get "/api/v1/products/#{product.id}/stock_audit_entries", headers: auth_headers(admin)

      expect(JSON.parse(response.body)["data"]).to eq([])
    end

    it "returns 403 for operator" do
      product = create(:product)

      get "/api/v1/products/#{product.id}/stock_audit_entries", headers: auth_headers(operator)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for a product that doesn't exist" do
      get "/api/v1/products/999999/stock_audit_entries", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/stock_audit_entries/users" do
    it "returns only users who actually have at least one entry, sorted by name" do
      zebra = create(:user, name: "Zebra")
      abacaxi = create(:user, name: "Abacaxi")
      create(:user, name: "Sem histórico nenhum")
      create(:stock_audit_entry, user: zebra)
      create(:stock_audit_entry, user: abacaxi)

      get "/api/v1/stock_audit_entries/users", headers: auth_headers(admin)

      body = JSON.parse(response.body)["data"]
      expect(body).to eq([
        { "id" => abacaxi.id, "name" => "Abacaxi" },
        { "id" => zebra.id, "name" => "Zebra" }
      ])
    end

    it "returns 403 for operator" do
      get "/api/v1/stock_audit_entries/users", headers: auth_headers(operator)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
