# This migration comes from kaui (originally 20130812155313)
class DeviseCreateKauiUsers < ActiveRecord::Migration
  def change
    create_table(:kaui_users) do |t|
      # From Kill Bill
      t.string :kb_username,  :null => false
      t.string :kb_session_id,  :null => true
      t.timestamps
    end

    add_index :kaui_users, [:kb_username], :unique => true
  end
end
