module KillBillClient
  module Model
    class TagDefinition < TagDefinitionAttributes

      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_TAG_DEFINITIONS_PREFIX = "#{KILLBILL_API_PREFIX}/tagDefinitions"

      has_audit_logs_with_history KILLBILL_API_TAG_DEFINITIONS_PREFIX, :id

      class << self
        def all(audit = 'NONE', options = {})
          get KILLBILL_API_TAG_DEFINITIONS_PREFIX,
              {
                  :audit => audit
              },
              options
        end

        def find_by_id(id, audit = 'NONE', options = {})
          get "#{KILLBILL_API_TAG_DEFINITIONS_PREFIX}/#{id}",
              {
                  :audit => audit
              },
              options
        end

        def find_by_name(name, audit = 'NONE', options = {})
          self.all(audit, options).select { |tag_definition| tag_definition.name == name }.first
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_tag_definition = self.class.post KILLBILL_API_TAG_DEFINITIONS_PREFIX,
                                                 to_json,
                                                 {},
                                                 {
                                                     :user    => user,
                                                     :reason  => reason,
                                                     :comment => comment,
                                                 }.merge(options)
        created_tag_definition.refresh(options)
      end

      def delete(user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{KILLBILL_API_TAG_DEFINITIONS_PREFIX}/#{id}",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end
    end
  end
end
