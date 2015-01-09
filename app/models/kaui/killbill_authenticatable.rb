require 'killbill_client'

module Devise
  module Models
    module KillbillAuthenticatable
      extend ActiveSupport::Concern

      def valid_killbill_password?(kb_username, kb_password)
        # Simply try to look-up the permissions for that user - this will
        # Take care of the auth part
        response = Kaui::User.find_permissions(kb_username, kb_password)
        # Auth was successful, update the session id
        self.kb_session_id = response.session_id
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
        def find_for_killbill_authentication(kb_username, kb_password, api_key, api_secret)
          kb_tenant_id = nil

          # Only in the Multi-Tenancy usecase
          if api_key.present?
            tenant = KillBillClient::Model::Tenant.find_by_api_key api_key, {
                                                                              :username => kb_username,
                                                                              :password => kb_password,
                                                                              :api_key => api_key,
                                                                              :api_secret => api_secret
                                                                            }
            kb_tenant_id = tenant.tenant_id if tenant.present?
          end

          find_for_authentication(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username) ||
          new(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username)
        rescue KillBillClient::API::Unauthorized => e
          # Multi-Tenancy was enabled, but the tenant_id couldn't be retrieved because of bad credentials
          nil
        end
      end
    end
  end
end
