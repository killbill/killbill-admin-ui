module Kaui
  module DateHelper

    LOCAL_DATE_RE = /^\d+-\d+-\d+$/

    def format_date(date, timezone)
      # Double check this is not null
      return nil if date.nil?

      # If this is a local date we assume this is already in the account timezone, and so there is nothing to do
      return date.to_s if LOCAL_DATE_RE.match(date.to_s)

      # If timezone is unknown, don't be clever and simply return the datetime
      # See https://github.com/killbill/killbill-admin-ui/issues/99
      return date.to_s if timezone.blank?

      # If not, convert into account timezone and return the date part only
      parsed_date = DateTime.parse(date.to_s).in_time_zone(timezone)
      parsed_date.to_s(:date_only)
    end

    def truncate_millis(date_s)
      DateTime.parse(date_s).strftime('%FT%T')
    end

    def current_time(timezone=nil)

      # if no timezone is passed return the time as it
      return Time.now if timezone.nil?

      current_utc_time = nil
      begin
        # fetch time from killbill server
        clock = Kaui::Admin.get_clock(timezone, Kaui.current_tenant_user_options(current_user, session))
        current_utc_time = clock['currentUtcTime']
      rescue KillBillClient::API::NotFound
        # Failed to get current KB clock: Kill Bill server must be started with system property org.killbill.server.test.mode=true
        # fetch it from time class
        current_utc_time = Time.now.utc
      end

      DateTime.parse(current_utc_time.to_s).in_time_zone(timezone)
    end
  end
end
