module Kaui
  module DateHelper
    def format_date(date, timezone="Pacific Time (US & Canada)")
      parsed_date = DateTime.parse(date.to_s).in_time_zone(timezone)
      parsed_date.to_s(:date_only)
    end
  end
end