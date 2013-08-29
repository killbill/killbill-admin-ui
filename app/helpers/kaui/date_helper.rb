module Kaui
  module DateHelper

    LOCAL_DATE_RE = /^\d+-\d+-\d+$/

    def format_date(date, timezone="Pacific Time (US & Canada)")

      # Double check this is not null
      return nil if date.nil?

      # If this is a local date we assume this is already in the account timezone, and so there is nothing to do
      return date.to_s if LOCAL_DATE_RE.match(date.to_s)

      # If not, convert into account timezone and return the date part only
      parsed_date = DateTime.parse(date.to_s).in_time_zone(timezone)
      parsed_date.to_s(:date_only)
    end
  end
end