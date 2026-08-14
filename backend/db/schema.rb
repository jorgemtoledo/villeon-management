# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_14_212407) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "product_stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "current_quantity", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "ideal_quantity", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "minimum_quantity", precision: 12, scale: 4, default: "0.0", null: false
    t.boolean "needs_advance_order"
    t.string "priority"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_stocks_on_product_id", unique: true
    t.check_constraint "current_quantity >= 0::numeric", name: "product_stocks_current_quantity_check"
    t.check_constraint "ideal_quantity >= 0::numeric", name: "product_stocks_ideal_quantity_check"
    t.check_constraint "minimum_quantity >= 0::numeric", name: "product_stocks_minimum_quantity_check"
    t.check_constraint "priority::text = ANY (ARRAY['critical'::character varying::text, 'normal'::character varying::text, 'low'::character varying::text])", name: "product_stocks_priority_check"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.boolean "preferred", default: false, null: false
    t.bigint "product_id", null: false
    t.bigint "supplier_id", null: false
    t.string "supplier_product_code"
    t.datetime "updated_at", null: false
    t.index ["product_id", "supplier_id"], name: "index_product_suppliers_on_product_id_and_supplier_id", unique: true
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["supplier_id"], name: "index_product_suppliers_on_supplier_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.string "code", null: false
    t.string "colibri_code"
    t.decimal "conversion_factor", precision: 12, scale: 4, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "purchase_unit_id", null: false
    t.bigint "sector_id", null: false
    t.bigint "stock_unit_id", null: false
    t.bigint "subcategory_id"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["code"], name: "index_products_on_code", unique: true
    t.index ["colibri_code"], name: "index_products_on_colibri_code"
    t.index ["purchase_unit_id"], name: "index_products_on_purchase_unit_id"
    t.index ["sector_id"], name: "index_products_on_sector_id"
    t.index ["stock_unit_id"], name: "index_products_on_stock_unit_id"
    t.index ["subcategory_id"], name: "index_products_on_subcategory_id"
    t.check_constraint "conversion_factor > 0::numeric", name: "products_conversion_factor_check"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.decimal "quantity", precision: 12, scale: 4, null: false
    t.decimal "total_price", precision: 12, scale: 2, null: false
    t.decimal "unit_price", precision: 12, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
    t.check_constraint "quantity > 0::numeric", name: "purchase_items_quantity_check"
    t.check_constraint "total_price >= 0::numeric", name: "purchase_items_total_price_check"
    t.check_constraint "unit_price >= 0::numeric", name: "purchase_items_unit_price_check"
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invoice_number"
    t.text "notes"
    t.datetime "purchased_at", null: false
    t.bigint "supplier_id", null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_number"], name: "index_purchases_on_invoice_number"
    t.index ["purchased_at"], name: "index_purchases_on_purchased_at"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.check_constraint "total_amount >= 0::numeric", name: "purchases_total_amount_check"
  end

  create_table "sectors", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sectors_on_name", unique: true
  end

  create_table "stock_audit_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field", null: false
    t.string "new_value"
    t.string "previous_value"
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.index ["field"], name: "index_stock_audit_entries_on_field"
    t.index ["product_id", "created_at"], name: "index_stock_audit_entries_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_stock_audit_entries_on_product_id"
    t.index ["user_id"], name: "index_stock_audit_entries_on_user_id"
  end

  create_table "stock_counts", force: :cascade do |t|
    t.datetime "counted_at", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["counted_at"], name: "index_stock_counts_on_counted_at"
    t.index ["product_id"], name: "index_stock_counts_on_product_id"
    t.index ["user_id"], name: "index_stock_counts_on_user_id"
    t.check_constraint "quantity >= 0::numeric", name: "stock_counts_quantity_check"
  end

  create_table "subcategories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
    t.index ["code"], name: "index_subcategories_on_code", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "cnpj"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_suppliers_on_cnpj", unique: true
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "units", force: :cascade do |t|
    t.string "abbreviation", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_units_on_abbreviation", unique: true
  end

  create_table "user_sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "sector_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["sector_id"], name: "index_user_sectors_on_sector_id"
    t.index ["user_id", "sector_id"], name: "index_user_sectors_on_user_id_and_sector_id", unique: true
    t.index ["user_id"], name: "index_user_sectors_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "all_sectors", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "operator", null: false
    t.bigint "sector_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["sector_id"], name: "index_users_on_sector_id"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying::text, 'manager'::character varying::text, 'operator'::character varying::text])", name: "users_role_check"
  end

  add_foreign_key "product_stocks", "products"
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "suppliers"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "sectors"
  add_foreign_key "products", "subcategories"
  add_foreign_key "products", "units", column: "purchase_unit_id"
  add_foreign_key "products", "units", column: "stock_unit_id"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "stock_audit_entries", "products"
  add_foreign_key "stock_audit_entries", "users"
  add_foreign_key "stock_counts", "products"
  add_foreign_key "stock_counts", "users"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "user_sectors", "sectors"
  add_foreign_key "user_sectors", "users"
  add_foreign_key "users", "sectors"
end
