module KillBillClient
  module Model
    class UserRoles < UserRolesAttributes

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_user = self.class.post "#{Security::KILLBILL_API_SECURITY_PREFIX}/users",
                                       to_json,
                                       {},
                                       {
                                           :user => user,
                                           :reason => reason,
                                           :comment => comment,
                                       }.merge(options)
        created_user.refresh(options)
      end

      def update(user = nil, reason = nil, comment = nil, options = {})
        url = password.nil? ? "#{Security::KILLBILL_API_SECURITY_PREFIX}/users/#{username}/roles" : "#{Security::KILLBILL_API_SECURITY_PREFIX}/users/#{username}/password"
        updated_user = self.class.put url,
                                      to_json,
                                      {},
                                      {
                                          :user => user,
                                          :reason => reason,
                                          :comment => comment,
                                      }.merge(options)
        updated_user.refresh(options)
      end

      def destroy(user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{Security::KILLBILL_API_SECURITY_PREFIX}/users/#{username}",
                          {},
                          {},
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def list(options = {})
        self.class.get "#{Security::KILLBILL_API_SECURITY_PREFIX}/users/#{username}/roles",
                       {},
                       {}.merge(options)
      end
    end
  end
end
