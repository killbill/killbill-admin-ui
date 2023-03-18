# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2015_01_12_232813) do

  create_table "kaui_allowed_user_tenants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "kaui_allowed_user_id"
    t.integer "kaui_tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kaui_allowed_user_id", "kaui_tenant_id"], name: "kaui_allowed_user_tenants_uniq", unique: true
    t.index ["kaui_allowed_user_id"], name: "index_kaui_allowed_user_tenants_on_kaui_allowed_user_id"
    t.index ["kaui_tenant_id"], name: "index_kaui_allowed_user_tenants_on_kaui_tenant_id"
  end

  create_table "kaui_allowed_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "kb_username"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kb_username"], name: "index_kaui_allowed_users_on_kb_username", unique: true
  end

  create_table "kaui_tenants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "kb_tenant_id"
    t.string "api_key"
    t.string "encrypted_api_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kaui_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "kb_username", null: false
    t.string "kb_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kb_username"], name: "index_kaui_users_on_kb_username", unique: true
  end

end
