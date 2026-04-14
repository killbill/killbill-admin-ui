module KillBillClient
  module Model
    class UsageRecord < SubscriptionUsageRecordAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog


      KILLBILL_API_USAGES_PREFIX = "#{KILLBILL_API_PREFIX}/usages"

      class << self
        def find_by_subscription_id(subscription_id, start_date, end_date, options = {})
          params                  = {}
          params[:startDate] = start_date
          params[:endDate]  = end_date

          get "#{KILLBILL_API_USAGES_PREFIX}/#{subscription_id}",
              params,
              options,
              KillBillClient::Model::RolledUpUsageAttributes.new.class
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        self.class.post KILLBILL_API_USAGES_PREFIX,
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
