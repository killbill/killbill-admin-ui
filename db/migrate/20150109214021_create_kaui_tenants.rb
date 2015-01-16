class CreateKauiTenants < ActiveRecord::Migration
  def change
    create_table :kaui_tenants do |t|
      t.string :name
      t.string :kb_tenant_id
      t.string :api_key
      t.string :encrypted_api_secret

      t.timestamps
    end
  end
end
