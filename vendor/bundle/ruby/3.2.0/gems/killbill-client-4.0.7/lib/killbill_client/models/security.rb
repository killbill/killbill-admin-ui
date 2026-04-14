module KillBillClient
  module Model
    class Security < Resource
      KILLBILL_API_SECURITY_PREFIX = "#{KILLBILL_API_PREFIX}/security"

      class << self
        def find_permissions(options = {})
          get "#{KILLBILL_API_SECURITY_PREFIX}/permissions",
              {},
              options
        end

        def find_subject(options = {})
          get "#{KILLBILL_API_SECURITY_PREFIX}/subject",
              {},
              options,
              SubjectAttributes # Attribute object as Subject is not a Kill Bill resource
        end
      end
    end
  end
end
