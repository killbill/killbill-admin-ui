module KillBillClient
  module Model
    class Overdue < OverdueAttributes

      has_many :overdue_states, KillBillClient::Model::OverdueStateConfig

      KILLBILL_API_OVERDUE_PREFIX = "#{KILLBILL_API_PREFIX}/overdue"

      class << self

        def get_tenant_overdue_config_xml(options = {})

          require_multi_tenant_options!(options, "Retrieving an overdue config is only supported in multi-tenant mode")

          get "#{KILLBILL_API_OVERDUE_PREFIX}/xml",
              {},
              {
                  :head => {'Accept' => "text/xml"}
              }.merge(options)
        end

        def get_tenant_overdue_config_json(options = {})

          require_multi_tenant_options!(options, "Retrieving an overdue config is only supported in multi-tenant mode")

          get KILLBILL_API_OVERDUE_PREFIX,
              {},
              {
                  :head => {'Accept' => "application/json"}
              }.merge(options)
        end

        def upload_tenant_overdue_config_xml(body, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading an overdue config is only supported in multi-tenant mode")

          post "#{KILLBILL_API_OVERDUE_PREFIX}/xml",
               body,
               {
               },
               {
                   :head => {'Accept' => 'text/xml'},
                   :content_type => 'text/xml',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_overdue_config_xml(options)
        end

        def upload_tenant_overdue_config_json(body, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading an overdue config is only supported in multi-tenant mode")

          post KILLBILL_API_OVERDUE_PREFIX,
               body,
               {
               },
               {
                   :head => {'Accept' => 'application/json'},
                   :content_type => 'application/json',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_overdue_config_json(options)
        end

      end

    end
  end
end

