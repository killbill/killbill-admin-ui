module KillBillClient
  module Model
    class Credit < InvoiceItemAttributes
      KILLBILL_API_CREDITS_PREFIX = "#{KILLBILL_API_PREFIX}/credits"
      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_by_id(credit_id, options = {})
          get "#{KILLBILL_API_CREDITS_PREFIX}/#{credit_id}",
              {},
              options,
              InvoiceItemAttributes
        end
      end

      def create(auto_commit = false, user = nil, reason = nil, comment = nil, options = {})
        created_credits = self.class.post KILLBILL_API_CREDITS_PREFIX,
                                         [to_hash].to_json,
                                         {
                                             :autoCommit => auto_commit
                                         },
                                         {
                                             :user => user,
                                             :reason => reason,
                                             :comment => comment,
                                         }.merge(options)
        created_credits
      end

    end
  end
end
