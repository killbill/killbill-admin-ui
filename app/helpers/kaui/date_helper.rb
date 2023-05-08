# frozen_string_literal: true

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
      parsed_date.to_fs(:date_only)
    end

    def truncate_millis(date_s)
      DateTime.parse(date_s).strftime('%FT%T')
    end

    # Retrieve current killbill server time based on a time zone.
    # if no time zone is provided it will return UTC.
    # if the killbill server is not reachable it will return the time of the Kaui server
    # The arguments are:
    # +time_zone+:: The time zone of the current time to return.
    # +options+:: A hash that contains credentials needed to retrieve the time from the
    #             killbill server.
    def current_time(time_zone = nil, options = nil)
      current_utc_time = nil
      begin
        # fetch time from killbill server
        clock = Kaui::Admin.get_clock(time_zone, options || Kaui.current_tenant_user_options(current_user, session))
        current_utc_time = clock['currentUtcTime']
      rescue KillBillClient::API::NotFound, NameError
        # Failed to get current KB clock: Kill Bill server must be started with system property org.killbill.server.test.mode=true
        # fetch it from time class
        current_utc_time = Time.now.utc
      end

      # if time zone is not found return the utc time
      return current_utc_time if time_zone.nil?

      DateTime.parse(current_utc_time.to_s).in_time_zone(time_zone)
    end
  end
end
