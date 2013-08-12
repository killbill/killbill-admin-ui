class DeviseCreateKauiUsers < ActiveRecord::Migration
  def change
    create_table(:kaui_users) do |t|
      # From Kill Bill
      t.string :kb_tenant_id, :null => true
      t.string :kb_username,  :null => false

      t.timestamps
    end

    add_index :kaui_users, [:kb_tenant_id, :kb_username], :unique => true
  end
end
