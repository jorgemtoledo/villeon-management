require "rails_helper"

RSpec.describe "Api::V1::Purchases", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/purchases" do
    it "is reachable by admin, manager and operator" do
      create(:purchase)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/purchases", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    it "requires authentication" do
      get "/api/v1/purchases"

      expect(response).to have_http_status(:unauthorized)
    end

    describe "pagination" do
      it "paginates with a default per_page and correct meta" do
        create_list(:purchase, 3)

        get "/api/v1/purchases", headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(3)
        expect(body["meta"]).to eq(
          { "page" => 1, "per_page" => 25, "total_pages" => 1, "total_count" => 3 }
        )
      end

      it "honors page and per_page" do
        create_list(:purchase, 5)

        get "/api/v1/purchases", params: { per_page: 2, page: 2 }, headers: auth_headers(admin)

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(2)
        expect(body["meta"]).to include("page" => 2, "per_page" => 2, "total_pages" => 3, "total_count" => 5)
      end

      it "clamps per_page to the maximum allowed" do
        create_list(:purchase, 3)

        get "/api/v1/purchases", params: { per_page: 999 }, headers: auth_headers(admin)

        expect(JSON.parse(response.body)["meta"]["per_page"]).to eq(100)
      end

      it "returns an empty page instead of an error when the requested page overflows" do
        create_list(:purchase, 2)

        get "/api/v1/purchases", params: { page: 50 }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["data"]).to eq([])
        expect(body["meta"]["total_count"]).to eq(2)
      end
    end

    describe "search (q)" do
      it "matches by supplier name or invoice number, case-insensitively" do
        matched_by_supplier = create(:purchase, supplier: create(:supplier, name: "Distribuidora ABC"))
        matched_by_invoice = create(:purchase, invoice_number: "NF-12345")
        create(:purchase, supplier: create(:supplier, name: "Nada a ver"))

        get "/api/v1/purchases", params: { q: "distribuidora" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matched_by_supplier.id)

        get "/api/v1/purchases", params: { q: "nf-123" }, headers: auth_headers(admin)
        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(matched_by_invoice.id)
      end
    end

    describe "filters" do
      it "filters by supplier_id" do
        supplier = create(:supplier)
        in_supplier = create(:purchase, supplier: supplier)
        create(:purchase)

        get "/api/v1/purchases", params: { supplier_id: supplier.id }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(in_supplier.id)
      end

      it "filters by date_from and date_to" do
        old_purchase = create(:purchase, purchased_at: Date.new(2026, 1, 5))
        in_range = create(:purchase, purchased_at: Date.new(2026, 3, 15))
        future_purchase = create(:purchase, purchased_at: Date.new(2026, 6, 1))

        get "/api/v1/purchases",
          params: { date_from: "2026-02-01", date_to: "2026-04-01" }, headers: auth_headers(admin)

        ids = JSON.parse(response.body)["data"].map { |p| p["id"] }
        expect(ids).to contain_exactly(in_range.id)
        expect(ids).not_to include(old_purchase.id, future_purchase.id)
      end

      it "ignores an unparseable date instead of erroring" do
        create(:purchase)

        get "/api/v1/purchases", params: { date_from: "not-a-date" }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
      end
    end

    describe "sorting" do
      it "defaults to purchased_at descending" do
        older = create(:purchase, purchased_at: Date.new(2026, 1, 1))
        newer = create(:purchase, purchased_at: Date.new(2026, 6, 1))

        get "/api/v1/purchases", headers: auth_headers(admin)

        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to eq([ newer.id, older.id ])
      end

      it "sorts by the given column and direction" do
        cheap = create(:purchase, total_amount: 50)
        expensive = create(:purchase, total_amount: 500)

        get "/api/v1/purchases", params: { sort: "total_amount", order: "asc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to eq([ cheap.id, expensive.id ])

        get "/api/v1/purchases", params: { sort: "total_amount", order: "desc" }, headers: auth_headers(admin)
        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to eq([ expensive.id, cheap.id ])
      end

      it "falls back to sorting by purchased_at when an unknown/unsafe column is requested" do
        older = create(:purchase, purchased_at: Date.new(2026, 1, 1))
        newer = create(:purchase, purchased_at: Date.new(2026, 6, 1))

        get "/api/v1/purchases", params: { sort: "id; DROP TABLE purchases;--" }, headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"].map { |p| p["id"] }).to eq([ newer.id, older.id ])
      end
    end

    it "includes items_count without N+1, matching the real item count" do
      purchase_with_items = create(:purchase)
      create_list(:purchase_item, 3, purchase: purchase_with_items)
      create(:purchase)

      get "/api/v1/purchases", headers: auth_headers(admin)

      counts = JSON.parse(response.body)["data"].to_h { |p| [ p["id"], p["items_count"] ] }
      expect(counts[purchase_with_items.id]).to eq(3)
    end

    it "serializes the supplier reference and monetary value as expected" do
      supplier = create(:supplier, name: "Isar Alimentos")
      purchase = create(:purchase, supplier: supplier, total_amount: 214.0)

      get "/api/v1/purchases", headers: auth_headers(admin)

      item = JSON.parse(response.body)["data"].find { |p| p["id"] == purchase.id }
      expect(item["supplier"]).to eq({ "id" => supplier.id, "name" => "Isar Alimentos" })
      expect(item["total_amount"]).to eq("214.0")
    end
  end

  describe "GET /api/v1/purchases/:id" do
    it "is reachable by all roles and includes items with product/unit data" do
      unit = create(:unit, name: "Quilograma", abbreviation: "kg")
      product = create(:product, name: "Filé Mignon", code: "COZ-001", purchase_unit: unit)
      purchase = create(:purchase)
      item = create(:purchase_item, purchase: purchase, product: product, quantity: 2, unit_price: 10)

      [ admin, manager, operator ].each do |user|
        get "/api/v1/purchases/#{purchase.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end

      body = JSON.parse(response.body)
      expect(body["items"].size).to eq(1)
      returned_item = body["items"].first
      expect(returned_item["product"]).to eq({ "id" => product.id, "name" => "Filé Mignon", "code" => "COZ-001" })
      expect(returned_item["unit"]).to eq({ "id" => unit.id, "name" => "Quilograma", "abbreviation" => "kg" })
      expect(returned_item["quantity"]).to eq("2.0")
      expect(returned_item["total_price"]).to eq(item.total_price.to_s)
    end

    it "returns invoice_number as nil when not present" do
      purchase = create(:purchase, invoice_number: nil)

      get "/api/v1/purchases/#{purchase.id}", headers: auth_headers(admin)

      expect(JSON.parse(response.body)["invoice_number"]).to be_nil
    end

    it "returns invoice_number when present" do
      purchase = create(:purchase, invoice_number: "NF-999")

      get "/api/v1/purchases/#{purchase.id}", headers: auth_headers(admin)

      expect(JSON.parse(response.body)["invoice_number"]).to eq("NF-999")
    end

    it "returns 404 JSON for an unknown id" do
      get "/api/v1/purchases/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "POST /api/v1/purchases" do
    let(:supplier) { create(:supplier) }
    let(:product) { create(:product) }
    let(:other_product) { create(:product) }

    let(:valid_params) do
      {
        purchase: {
          supplier_id: supplier.id,
          purchased_at: "2026-08-01",
          invoice_number: "NF-1000",
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 }
          ]
        }
      }
    end

    it "allows admin to create a purchase" do
      post "/api/v1/purchases", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
    end

    it "allows manager to create a purchase" do
      post "/api/v1/purchases", params: valid_params, headers: auth_headers(manager), as: :json

      expect(response).to have_http_status(:created)
    end

    it "forbids operator from creating a purchase" do
      post "/api/v1/purchases", params: valid_params, headers: auth_headers(operator), as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a user with no purchase-creation permission from creating a purchase" do
      no_permission_user = create(:user, role: "operator", password: "password123")

      post "/api/v1/purchases", params: valid_params, headers: auth_headers(no_permission_user), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(Purchase.count).to eq(0)
    end

    it "returns 422 for a nonexistent supplier" do
      invalid_params = valid_params.deep_merge(purchase: { supplier_id: 999999 })

      post "/api/v1/purchases", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a nonexistent product" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: 999999, quantity: 5, unit_price: 10 } ] })

      post "/api/v1/purchases", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an invalid quantity" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: product.id, quantity: 0, unit_price: 10 } ] })

      post "/api/v1/purchases", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an invalid unit_price" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: product.id, quantity: 5, unit_price: -1 } ] })

      post "/api/v1/purchases", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a purchase with no items" do
      invalid_params = valid_params.deep_merge(purchase: { items: [] })

      post "/api/v1/purchases", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
    end

    it "accepts multiple items in a single purchase" do
      multi_item_params = valid_params.deep_merge(
        purchase: {
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 },
            { product_id: other_product.id, quantity: 2, unit_price: 3.25 }
          ]
        }
      )

      post "/api/v1/purchases", params: multi_item_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["items"].size).to eq(2)
    end

    it "computes total_amount from the items, ignoring any total sent by the client" do
      params_with_bogus_total = valid_params.deep_merge(purchase: { total_amount: 999_999 })

      post "/api/v1/purchases", params: params_with_bogus_total, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      purchase = Purchase.last
      expect(purchase.total_amount).to eq(BigDecimal("52.50"))
      expect(JSON.parse(response.body)["total_amount"]).to eq("52.5")
    end

    it "keeps total_amount consistent with monetary precision (2 decimal places) across items" do
      multi_item_params = valid_params.deep_merge(
        purchase: {
          items: [
            { product_id: product.id, quantity: 3, unit_price: 3.33 },
            { product_id: other_product.id, quantity: 2, unit_price: 3.335 }
          ]
        }
      )

      post "/api/v1/purchases", params: multi_item_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      purchase = Purchase.last
      expected_total = purchase.purchase_items.sum(:total_price)
      expect(purchase.total_amount).to eq(expected_total)
    end

    it "rolls back the entire purchase when one item fails validation" do
      mixed_params = valid_params.deep_merge(
        purchase: {
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 },
            { product_id: other_product.id, quantity: -1, unit_price: 3.25 }
          ]
        }
      )

      expect {
        post "/api/v1/purchases", params: mixed_params, headers: auth_headers(admin), as: :json
      }.not_to change(Purchase, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(PurchaseItem.count).to eq(0)
    end

    it "does not create or change ProductStock when a purchase is registered" do
      expect {
        post "/api/v1/purchases", params: valid_params, headers: auth_headers(admin), as: :json
      }.not_to change(ProductStock, :count)

      expect(response).to have_http_status(:created)
      expect(product.reload.product_stock).to be_nil
    end

    it "does not change an existing ProductStock when a purchase is registered" do
      stock = create(:product_stock, product: product, current_quantity: 7, minimum_quantity: 2, ideal_quantity: 10)

      post "/api/v1/purchases", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      stock.reload
      expect(stock.current_quantity).to eq(BigDecimal("7"))
      expect(stock.minimum_quantity).to eq(BigDecimal("2"))
      expect(stock.ideal_quantity).to eq(BigDecimal("10"))
    end

    it "does not create a StockCount when a purchase is registered" do
      expect {
        post "/api/v1/purchases", params: valid_params, headers: auth_headers(admin), as: :json
      }.not_to change(StockCount, :count)

      expect(response).to have_http_status(:created)
    end

    it "serializes the newly created purchase using the same contract as GET /:id" do
      post "/api/v1/purchases", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["supplier"]).to eq({ "id" => supplier.id, "name" => supplier.name })
      expect(body["invoice_number"]).to eq("NF-1000")
      expect(body["items"].size).to eq(1)
      returned_item = body["items"].first
      expect(returned_item["product"]).to eq({ "id" => product.id, "name" => product.name, "code" => product.code })
      expect(returned_item["quantity"]).to eq("5.0")
      expect(returned_item["unit_price"]).to eq("10.5")
      expect(returned_item["total_price"]).to eq("52.5")
    end
  end

  describe "PATCH /api/v1/purchases/:id" do
    let(:supplier) { create(:supplier) }
    let(:other_supplier) { create(:supplier) }
    let(:product) { create(:product) }
    let(:other_product) { create(:product) }
    let(:purchase) { create(:purchase, supplier: supplier, purchased_at: "2026-08-01", invoice_number: "NF-OLD") }

    before do
      create(:purchase_item, purchase: purchase, product: product, quantity: 5, unit_price: 10)
    end

    let(:valid_params) do
      {
        purchase: {
          supplier_id: supplier.id,
          purchased_at: "2026-08-01",
          invoice_number: "NF-NEW",
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 }
          ]
        }
      }
    end

    it "allows admin to edit a purchase" do
      patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["invoice_number"]).to eq("NF-NEW")
    end

    it "allows manager to edit a purchase" do
      patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(manager), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "forbids operator from editing a purchase" do
      patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(operator), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(purchase.reload.invoice_number).to eq("NF-OLD")
    end

    it "returns 422 for a nonexistent supplier" do
      invalid_params = valid_params.deep_merge(purchase: { supplier_id: 999999 })

      patch "/api/v1/purchases/#{purchase.id}", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a nonexistent product" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: 999999, quantity: 5, unit_price: 10 } ] })

      patch "/api/v1/purchases/#{purchase.id}", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an invalid quantity" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: product.id, quantity: 0, unit_price: 10 } ] })

      patch "/api/v1/purchases/#{purchase.id}", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for an invalid unit_price" do
      invalid_params = valid_params.deep_merge(purchase: { items: [ { product_id: product.id, quantity: 5, unit_price: -1 } ] })

      patch "/api/v1/purchases/#{purchase.id}", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 JSON for an unknown purchase id" do
      patch "/api/v1/purchases/999999", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when edited to have no items" do
      invalid_params = valid_params.deep_merge(purchase: { items: [] })

      patch "/api/v1/purchases/#{purchase.id}", params: invalid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["details"]).to be_present
      expect(purchase.reload.purchase_items.count).to eq(1)
    end

    it "adds an item" do
      params_with_two_items = valid_params.deep_merge(
        purchase: {
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 },
            { product_id: other_product.id, quantity: 2, unit_price: 3.25 }
          ]
        }
      )

      patch "/api/v1/purchases/#{purchase.id}", params: params_with_two_items, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(purchase.reload.purchase_items.count).to eq(2)
    end

    it "removes an item" do
      create(:purchase_item, purchase: purchase, product: other_product, quantity: 1, unit_price: 1)
      expect(purchase.purchase_items.count).to eq(2)

      patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(purchase.reload.purchase_items.count).to eq(1)
      expect(purchase.purchase_items.first.product_id).to eq(product.id)
    end

    it "changes an item's product, quantity and price" do
      changed_params = valid_params.deep_merge(
        purchase: { items: [ { product_id: other_product.id, quantity: 9, unit_price: 2.25 } ] }
      )

      patch "/api/v1/purchases/#{purchase.id}", params: changed_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      item = purchase.reload.purchase_items.sole
      expect(item.product_id).to eq(other_product.id)
      expect(item.quantity).to eq(BigDecimal("9"))
      expect(item.unit_price).to eq(BigDecimal("2.25"))
    end

    it "recalculates total_amount from the edited items, ignoring any total sent by the client" do
      params_with_bogus_total = valid_params.deep_merge(
        purchase: { total_amount: 999_999, items: [ { product_id: product.id, quantity: 2, unit_price: 10 } ] }
      )

      patch "/api/v1/purchases/#{purchase.id}", params: params_with_bogus_total, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      expect(purchase.reload.total_amount).to eq(BigDecimal("20.00"))
      expect(JSON.parse(response.body)["total_amount"]).to eq("20.0")
    end

    it "keeps total_amount consistent with monetary precision (2 decimal places) across edited items" do
      params_with_precision = valid_params.deep_merge(
        purchase: {
          items: [
            { product_id: product.id, quantity: 3, unit_price: 3.33 },
            { product_id: other_product.id, quantity: 2, unit_price: 3.335 }
          ]
        }
      )

      patch "/api/v1/purchases/#{purchase.id}", params: params_with_precision, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      purchase.reload
      expected_total = purchase.purchase_items.sum(:total_price)
      expect(purchase.total_amount).to eq(expected_total)
    end

    it "rolls back the entire edit when one item fails validation, keeping the original items intact" do
      mixed_params = valid_params.deep_merge(
        purchase: {
          invoice_number: "SHOULD-NOT-PERSIST",
          items: [
            { product_id: product.id, quantity: 5, unit_price: 10.50 },
            { product_id: other_product.id, quantity: -1, unit_price: 3.25 }
          ]
        }
      )

      original_item_id = purchase.purchase_items.first.id

      patch "/api/v1/purchases/#{purchase.id}", params: mixed_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      purchase.reload
      expect(purchase.invoice_number).to eq("NF-OLD")
      expect(purchase.purchase_items.count).to eq(1)
      expect(purchase.purchase_items.first.id).to eq(original_item_id)
    end

    it "does not create or change ProductStock when a purchase is edited" do
      stock = create(:product_stock, product: product, current_quantity: 7, minimum_quantity: 2, ideal_quantity: 10)

      expect {
        patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(admin), as: :json
      }.not_to change(ProductStock, :count)

      expect(response).to have_http_status(:ok)
      stock.reload
      expect(stock.current_quantity).to eq(BigDecimal("7"))
      expect(stock.minimum_quantity).to eq(BigDecimal("2"))
      expect(stock.ideal_quantity).to eq(BigDecimal("10"))
    end

    it "does not create a StockCount when a purchase is edited" do
      expect {
        patch "/api/v1/purchases/#{purchase.id}", params: valid_params, headers: auth_headers(admin), as: :json
      }.not_to change(StockCount, :count)

      expect(response).to have_http_status(:ok)
    end

    it "does not deduplicate existing exact-duplicate items when the purchase is edited" do
      duplicate_purchase = create(:purchase, supplier: supplier, purchased_at: "2026-08-02")
      create(:purchase_item, purchase: duplicate_purchase, product: product, quantity: 4, unit_price: 6)
      create(:purchase_item, purchase: duplicate_purchase, product: product, quantity: 4, unit_price: 6)

      resend_duplicates_params = {
        purchase: {
          supplier_id: supplier.id,
          purchased_at: "2026-08-02",
          items: [
            { product_id: product.id, quantity: 4, unit_price: 6 },
            { product_id: product.id, quantity: 4, unit_price: 6 }
          ]
        }
      }

      patch "/api/v1/purchases/#{duplicate_purchase.id}", params: resend_duplicates_params, headers: auth_headers(admin), as: :json

      expect(response).to have_http_status(:ok)
      items = duplicate_purchase.reload.purchase_items
      expect(items.count).to eq(2)
      expect(items.pluck(:product_id)).to eq([ product.id, product.id ])
      expect(items.pluck(:quantity)).to all(eq(BigDecimal("4")))
      expect(items.pluck(:unit_price)).to all(eq(BigDecimal("6")))
    end
  end
end
