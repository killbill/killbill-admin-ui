# frozen_string_literal: true

class CreateKauiTenants < ActiveRecord::Migration[5.0]
  def change
    return if table_exists?(:kaui_tenants)

    create_table :kaui_tenants do |t|
      t.string :name
      t.string :kb_tenant_id
      t.string :api_key
      t.string :encrypted_api_secret

      t.timestamps
    end
  end
end
