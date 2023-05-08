# frozen_string_literal: true

require 'killbill_client'

# Hack for Zeitwerk
module Kaui
  module KillbillAuthenticatable; end
end

module Devise
  module Models
    module KillbillAuthenticatable
      extend ActiveSupport::Concern

      def valid_killbill_password?(creds)
        # Simply try to look-up the permissions for that user - this will
        # Take care of the auth part
        response = Kaui::User.find_permissions(creds)
        # Auth was successful, update the session id
        self.kb_session_id = response.session_id
        true
      rescue KillBillClient::API::Unauthorized => _e
        false
      end

      def after_killbill_authentication
        save(validate: false)
      end

      module ClassMethods
        # Invoked by the KillbillAuthenticatable strategy to lookup the user
        # before attempting authentication
        def find_for_killbill_authentication(kb_username)
          find_for_authentication(kb_username:) ||
            new(kb_username:)
        rescue KillBillClient::API::Unauthorized => _e
          # Multi-Tenancy was enabled, but the tenant_id couldn't be retrieved because of bad credentials
          nil
        end
      end
    end
  end
end
