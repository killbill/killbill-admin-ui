class Kaui::TimeSeriesData < Kaui::Base
  define_attr :dates
  define_attr :values

  def self.empty
    Kaui::TimeSeriesData.new(:dates => [], :values => [])
  end
end
