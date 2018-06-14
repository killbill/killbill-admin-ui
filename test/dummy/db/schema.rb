# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151210120915) do

  create_table "kaui_allowed_user_tenants", id: :bigint, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin" do |t|
    t.bigint "kaui_allowed_user_id", unsigned: true
    t.bigint "kaui_tenant_id", unsigned: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "id", unique: true
    t.index ["kaui_allowed_user_id", "kaui_tenant_id"], name: "kaui_allowed_users_tenants_uniq", unique: true
  end

  create_table "kaui_allowed_users", id: :bigint, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin" do |t|
    t.string "kb_username"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "id", unique: true
    t.index ["kb_username"], name: "kaui_allowed_users_idx", unique: true
  end

  create_table "kaui_tenants", id: :bigint, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin" do |t|
    t.string "name", null: false
    t.string "kb_tenant_id"
    t.string "api_key"
    t.string "encrypted_api_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "kaui_tenants_kb_api_key", unique: true
    t.index ["id"], name: "id", unique: true
    t.index ["kb_tenant_id"], name: "kaui_tenants_kb_tenant_id", unique: true
    t.index ["name"], name: "kaui_tenants_kb_name", unique: true
  end

  create_table "kaui_users", id: :bigint, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin" do |t|
    t.string "kb_username", null: false
    t.string "kb_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "id", unique: true
    t.index ["kb_username"], name: "index_kaui_users_on_kb_username", unique: true
  end

end
