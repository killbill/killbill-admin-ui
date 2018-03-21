class DeviseCreateKauiUsers < ActiveRecord::Migration[5.0]
  def change
    unless table_exists?(:kaui_users)
      create_table(:kaui_users) do |t|
        # From Kill Bill
        t.string :kb_username,  :null => false
        t.string :kb_session_id,  :null => true
        t.timestamps
      end

      add_index :kaui_users, [:kb_username], :unique => true
    end
  end
end
