module KillBillClient
  module Model
    class RolledUpUsage < RolledUpUsageAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :rolled_up_units, KillBillClient::Model::RolledUpUnitAttributes

      KILLBILL_API_USAGES_PREFIX = "#{KILLBILL_API_PREFIX}/usages"

      class << self
        def find_by_subscription_id(subscription_id, start_date, end_date, options = {})
          find_by_subscription_id_and_type(subscription_id, start_date, end_date, nil, options)
        end

        def find_by_subscription_id_and_type(subscription_id, start_date, end_date, unit_type, options = {})
          params                  = {}
          params[:startDate] = start_date
          params[:endDate]  = end_date

          path = "#{KILLBILL_API_USAGES_PREFIX}/#{subscription_id}"
          path = "#{path}/#{unit_type}" if unit_type
          get path,
              params,
              options
        end
      end

    end
  end
end
