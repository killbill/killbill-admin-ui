class Kaui::UserRole < KillBillClient::Model::UserRoles

  def self.find_roles_by_username(username, options = {})
    user_role = Kaui::UserRole.new
    user_role.username = username
    user_role.list(options).roles
  end
end
