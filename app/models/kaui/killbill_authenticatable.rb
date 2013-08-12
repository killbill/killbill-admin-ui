module Devise
  module Models
    module KillbillAuthenticatable
      extend ActiveSupport::Concern

      def valid_killbill_password?(kb_tenant_id, kb_username, kb_password)
        # TODO talk to KB
        true
      end

      def after_killbill_authentication
        self.save(:validate => false)
      end

      module ClassMethods

        # Invoked by the KillbillAuthenticatable strategy to perform the authentication
        # against the Kill Bill server.
        def find_for_killbill_authentication(authentication_hash)
          kb_tenant_id = authentication_hash[:kb_tenant_id]
          kb_username = authentication_hash[:kb_username]
          kb_password = authentication_hash[:password]

          resource = find_for_authentication(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username) ||
                     new(:kb_tenant_id => kb_tenant_id, :kb_username => kb_username)

          resource.valid_killbill_password?(kb_tenant_id, kb_username, kb_password) ? resource : nil
        end
      end
    end
  end
end
