require "rails_helper"

RSpec.describe "Api::V1::ProductSuppliers", type: :request do
  let(:admin) { create(:user, role: "admin", password: "password123") }
  let(:manager) { create(:user, role: "manager", password: "password123") }
  let(:operator) { create(:user, role: "operator", password: "password123") }

  def auth_headers(user)
    { "Authorization" => "Bearer #{jwt_for(user)}" }
  end

  describe "GET /api/v1/products/:product_id/suppliers" do
    it "is reachable by admin, manager and operator and lists suppliers with pivot data" do
      product = create(:product)
      supplier = create(:supplier)
      create(:product_supplier,
        product: product, supplier: supplier, preferred: true, supplier_product_code: "SUP-1", notes: "nota")

      [ admin, manager, operator ].each do |user|
        get "/api/v1/products/#{product.id}/suppliers", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first).to include(
        "preferred" => true,
        "supplier_product_code" => "SUP-1",
        "notes" => "nota",
        "supplier" => { "id" => supplier.id, "name" => supplier.name, "cnpj" => supplier.cnpj }
      )
    end

    it "returns an empty list for a product without linked suppliers" do
      product = create(:product)

      get "/api/v1/products/#{product.id}/suppliers", headers: auth_headers(admin)

      expect(JSON.parse(response.body)).to eq([])
    end

    it "lists the principal first, then alternates ordered by supplier name" do
      product = create(:product)
      supplier_z = create(:supplier, name: "Zebra Alimentos")
      supplier_a = create(:supplier, name: "Alpha Alimentos")
      supplier_principal = create(:supplier, name: "Meio Alimentos")
      create(:product_supplier, product: product, supplier: supplier_z, preferred: false)
      create(:product_supplier, product: product, supplier: supplier_a, preferred: false)
      create(:product_supplier, product: product, supplier: supplier_principal, preferred: true)

      get "/api/v1/products/#{product.id}/suppliers", headers: auth_headers(admin)

      names = JSON.parse(response.body).map { |item| item["supplier"]["name"] }
      expect(names).to eq([ "Meio Alimentos", "Alpha Alimentos", "Zebra Alimentos" ])
    end

    it "returns 404 JSON for an unknown product id" do
      get "/api/v1/products/999999/suppliers", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      product = create(:product)

      get "/api/v1/products/#{product.id}/suppliers"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/products/:product_id/suppliers" do
    it "lets admin add a principal supplier" do
      product = create(:product)
      supplier = create(:supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: supplier.id, preferred: true, supplier_product_code: "X1", notes: "obs" } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include(
        "preferred" => true, "supplier_product_code" => "X1", "notes" => "obs"
      )
    end

    it "lets admin add an alternate supplier" do
      product = create(:product)
      supplier = create(:supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: supplier.id, preferred: false } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["preferred"]).to eq(false)
    end

    it "supports several alternate suppliers for the same product" do
      product = create(:product)
      3.times do
        post "/api/v1/products/#{product.id}/suppliers",
          params: { product_supplier: { supplier_id: create(:supplier).id, preferred: false } },
          headers: auth_headers(admin)
        expect(response).to have_http_status(:created)
      end

      expect(product.product_suppliers.count).to eq(3)
    end

    it "demotes the previous principal when a new one is added as preferred" do
      product = create(:product)
      old_principal = create(:product_supplier, product: product, preferred: true)
      new_supplier = create(:supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: new_supplier.id, preferred: true } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(old_principal.reload.preferred).to eq(false)
      expect(product.product_suppliers.where(preferred: true).count).to eq(1)
    end

    it "rejects a duplicate product/supplier link with 422" do
      product = create(:product)
      supplier = create(:supplier)
      create(:product_supplier, product: product, supplier: supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: supplier.id } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 JSON for an unknown product id" do
      supplier = create(:supplier)

      post "/api/v1/products/999999/suppliers",
        params: { product_supplier: { supplier_id: supplier.id } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 JSON for an unknown supplier id" do
      product = create(:product)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: 999999 } },
        headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "forbids manager" do
      product = create(:product)
      supplier = create(:supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: supplier.id } },
        headers: auth_headers(manager)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids operator" do
      product = create(:product)
      supplier = create(:supplier)

      post "/api/v1/products/#{product.id}/suppliers",
        params: { product_supplier: { supplier_id: supplier.id } },
        headers: auth_headers(operator)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/products/:product_id/suppliers/:id/prefer" do
    it "lets admin swap the principal supplier" do
      product = create(:product)
      old_principal = create(:product_supplier, product: product, preferred: true)
      new_principal = create(:product_supplier, product: product, preferred: false)

      patch "/api/v1/products/#{product.id}/suppliers/#{new_principal.id}/prefer", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["preferred"]).to eq(true)
      expect(old_principal.reload.preferred).to eq(false)
      expect(new_principal.reload.preferred).to eq(true)
    end

    it "forbids manager and operator" do
      product = create(:product)
      link = create(:product_supplier, product: product, preferred: false)

      [ manager, operator ].each do |user|
        patch "/api/v1/products/#{product.id}/suppliers/#{link.id}/prefer", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v1/products/:product_id/suppliers/:id" do
    it "lets admin remove an alternate supplier" do
      product = create(:product)
      link = create(:product_supplier, product: product, preferred: false)

      delete "/api/v1/products/#{product.id}/suppliers/#{link.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(ProductSupplier.exists?(link.id)).to eq(false)
    end

    it "lets admin remove the principal supplier, leaving the product with none" do
      product = create(:product)
      link = create(:product_supplier, product: product, preferred: true)

      delete "/api/v1/products/#{product.id}/suppliers/#{link.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(product.product_suppliers.where(preferred: true)).to be_empty
    end

    it "returns 404 JSON for an unknown link id" do
      product = create(:product)

      delete "/api/v1/products/#{product.id}/suppliers/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end

    it "forbids manager and operator" do
      product = create(:product)
      link = create(:product_supplier, product: product)

      [ manager, operator ].each do |user|
        delete "/api/v1/products/#{product.id}/suppliers/#{link.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
