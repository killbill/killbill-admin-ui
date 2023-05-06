# frozen_string_literal: true

class CreateKauiAllowedUsers < ActiveRecord::Migration[5.0]
  def change
    unless table_exists?(:kaui_allowed_users)
      create_table :kaui_allowed_users do |t|
        t.string :kb_username
        t.string :description
        t.timestamps
      end

      add_index :kaui_allowed_users, [:kb_username], unique: true
    end

    return if table_exists?(:kaui_allowed_user_tenants)

    create_table :kaui_allowed_user_tenants do |t|
      t.belongs_to :kaui_allowed_user
      t.belongs_to :kaui_tenant
      t.timestamps null: false
    end

    add_index :kaui_allowed_user_tenants, %i[kaui_allowed_user_id kaui_tenant_id], unique: true, name: 'kaui_allowed_user_tenants_uniq'
  end
end
