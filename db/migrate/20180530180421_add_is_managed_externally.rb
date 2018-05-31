class AddIsManagedExternally < ActiveRecord::Migration[5.1]
  def change
    add_column :kaui_allowed_users, :is_managed_externally, :boolean, :default => 0, :after => :description
  end
end
