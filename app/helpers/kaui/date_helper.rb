module Kaui
  module DateHelper
    def format_date(date)
      # TODO: make timezone configurable
      parsed_date = DateTime.parse(date).in_time_zone("Pacific Time (US & Canada)")
      parsed_date.to_s(:pretty) + "&nbsp;" + (parsed_date.dst? ? "PDT" : "PST")
    end
  end
end