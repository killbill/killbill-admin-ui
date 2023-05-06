# frozen_string_literal: true

module Kaui
  class Admin < KillBillClient::Model::Resource
    KILLBILL_API_ADMIN_PREFIX = "#{KILLBILL_API_PREFIX}/admin".freeze
    KILLBILL_API_QUEUES_PREFIX = "#{KILLBILL_API_ADMIN_PREFIX}/queues".freeze

    KILLBILL_API_CLOCK_PREFIX = "#{KILLBILL_API_PREFIX}/test/clock".freeze

    class << self
      def get_queues_entries(account_id, options = {})
        res = KillBillClient::API.get KILLBILL_API_QUEUES_PREFIX,
                                      {
                                        accountId: account_id,
                                        withHistory: options[:withHistory],
                                        minDate: options[:minDate],
                                        maxDate: options[:maxDate]
                                      },
                                      {
                                        accept: 'application/octet-stream'
                                      }.merge(options)
        JSON.parse res.body
      end

      def fix_transaction_state(payment_id, transaction_id, transaction_status, user = nil, reason = nil, comment = nil, options = {})
        KillBillClient::API.put "#{KILLBILL_API_ADMIN_PREFIX}/payments/#{payment_id}/transactions/#{transaction_id}",
                                { transactionStatus: transaction_status }.to_json,
                                {},
                                {
                                  user:,
                                  reason:,
                                  comment:
                                }.merge(options)
      end

      def get_clock(time_zone, options)
        params = {}
        params[:timeZone] = time_zone unless time_zone.nil?

        res = KillBillClient::API.get KILLBILL_API_CLOCK_PREFIX,
                                      params,
                                      options
        JSON.parse res.body
      end

      def set_clock(requested_date, time_zone, options)
        params = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        params[:timeZone] = time_zone unless time_zone.nil?

        # The default 5s is not always enough
        params[:timeoutSec] ||= 10

        res = KillBillClient::API.post KILLBILL_API_CLOCK_PREFIX,
                                       {},
                                       params,
                                       {}.merge(options)
        JSON.parse res.body
      end

      def increment_kb_clock(days, weeks, months, years, time_zone, options)
        params = {}
        params[:days] = days unless days.nil?
        params[:weeks] = weeks unless weeks.nil?
        params[:months] = months unless months.nil?
        params[:years] = years unless years.nil?
        params[:timeZone] = time_zone unless time_zone.nil?

        # The default 5s is not always enough
        params[:timeoutSec] ||= 10

        res = KillBillClient::API.put KILLBILL_API_CLOCK_PREFIX,
                                      {},
                                      params,
                                      {}.merge(options)

        JSON.parse res.body
      end
    end
  end
end
