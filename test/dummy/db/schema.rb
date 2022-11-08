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

ActiveRecord::Schema.define(version: 2015_12_10_120915) do

  create_table "kaui_allowed_user_tenants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "kaui_allowed_user_id"
    t.integer "kaui_tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kaui_allowed_user_id", "kaui_tenant_id"], name: "kaui_allowed_user_tenants_uniq", unique: true
    t.index ["kaui_allowed_user_id"], name: "index_kaui_allowed_user_tenants_on_kaui_allowed_user_id"
    t.index ["kaui_tenant_id"], name: "index_kaui_allowed_user_tenants_on_kaui_tenant_id"
  end

  create_table "kaui_allowed_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "kb_username"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kb_username"], name: "index_kaui_allowed_users_on_kb_username", unique: true
  end

  create_table "kaui_tenants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "kb_tenant_id"
    t.string "api_key"
    t.string "encrypted_api_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kaui_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "kb_username", null: false
    t.string "kb_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kb_username"], name: "index_kaui_users_on_kb_username", unique: true
  end

end
