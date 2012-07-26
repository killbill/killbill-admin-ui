module Kaui
  module DateHelper
    def format_date(date)
      # TODO: make timezone configurable
      parsed_date = DateTime.parse(date).in_time_zone(ActiveSupport::TimeZone::ZONES_MAP["Pacific Time (US & Canada)"])
      parsed_date.to_s(:date_only)
    end
  end
end