require 'killbill_client'

module Devise
  module Models
    module KillbillAuthenticatable
      extend ActiveSupport::Concern

      included do
        attr_accessor :password
      end

      def valid_killbill_password?(kb_tenant_id, kb_username, kb_password)
        # Simply try to look-up the permissions for that user - this will
        # take care of the auth part.
        Kaui::User.find_permissions(kb_username, kb_password)
        true
      rescue KillBillClient::API::Unauthorized => e
        false
      end

      def after_killbill_authentication
        self.save(:validate => false)
      end

      module ClassMethods

        # Invoked by the KillbillAuthenticatable strategy to lookup the user
        # before attempting authentication
        def find_for_killbill_authentication(kb_tenant_id, kb_username, kb_password)
          find_for_authentication(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username) ||
          new(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username)
        end
      end
    end
  end
end
