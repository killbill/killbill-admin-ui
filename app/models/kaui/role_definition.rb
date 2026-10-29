# frozen_string_literal: true

module Kaui
  class RoleDefinition < KillBillClient::Model::RoleDefinition
    # Lists all the roles (Kill Bill 0.25+). Defined here because killbill-client releases up to 4.0.9 do not expose it.
    def self.find_all(options = {})
      return super if defined?(super)

      get "#{KillBillClient::Model::Security::KILLBILL_API_SECURITY_PREFIX}/roles", {}, options
    end
  end
end
