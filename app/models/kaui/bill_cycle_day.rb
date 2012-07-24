class Kaui::BillCycleDay < Kaui::Base
  define_attr :day_of_month_local
  define_attr :day_of_month_utc

  def initialize(data = {})
    super(:day_of_month_local => data['dayOfMonthLocal'],
          :day_of_month_utc => data['dayOfMonthUTC'])
  end
end
