require 'test_helper'

class Kaui::BillCycleDayTest < ActiveSupport::TestCase
  fixtures :bill_cycle_days

  test "can serialize from json" do
    as_json = bill_cycle_days(:the_sixth)
    the_sixth = Kaui::BillCycleDay.new(as_json)

    assert_equal as_json["dayOfMonthUTC"], the_sixth.day_of_month_utc
    assert_equal as_json["dayOfMonthLocal"], the_sixth.day_of_month_local
  end
end