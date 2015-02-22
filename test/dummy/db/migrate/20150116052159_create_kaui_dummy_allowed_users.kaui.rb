# This migration comes from kaui (originally 20150112232813)
class CreateKauiDummyAllowedUsers < ActiveRecord::Migration
  def change
    create_table :kaui_allowed_users do |t|
      t.string :kb_username
      t.string :description
      t.timestamps
    end

    add_index :kaui_allowed_users, [:kb_username], :unique => true

    create_table :kaui_allowed_user_tenants do |t|
      t.belongs_to :kaui_allowed_user, :index => true
      t.belongs_to :kaui_tenant, :index => true
      t.timestamps null: false
    end

    add_index :kaui_allowed_user_tenants, [:kaui_allowed_user_id, :kaui_tenant_id], :unique => true, :name => 'kaui_allowed_user_tenants_uniq'
  end
end
