module KillBillClient
  module Model
    class RoleDefinition < RoleDefinitionAttributes

      class << self
        def find_by_name(role_name, options = {})
          role = get "#{Security::KILLBILL_API_SECURITY_PREFIX}/roles/#{role_name}",
                                        {},
                                        options
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_role = self.class.post "#{Security::KILLBILL_API_SECURITY_PREFIX}/roles",
                                       to_json,
                                       {},
                                       {
                                           :user => user,
                                           :reason => reason,
                                           :comment => comment,
                                       }.merge(options)
        created_role.refresh(options)
      end

      def update(user = nil, reason = nil, comment = nil, options = {})
        self.class.put "#{Security::KILLBILL_API_SECURITY_PREFIX}/roles",
                                       to_json,
                                       {},
                                       {
                                           :user => user,
                                           :reason => reason,
                                           :comment => comment,
                                       }.merge(options)
      end
    end
  end
end
