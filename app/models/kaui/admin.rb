class Kaui::Admin < KillBillClient::Model::Resource

  KILLBILL_API_CLOCK_PREFIX = "#{KILLBILL_API_PREFIX}/test/clock"

  class << self

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
