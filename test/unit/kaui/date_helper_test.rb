require 'test_helper'

class Kaui::DateHelperTest < ActiveSupport::TestCase

  include Kaui::DateHelper

  test 'can parse from string' do
    assert_equal '2012-07-01', format_date('2012-07-01T12:55:44Z', 'Pacific Time (US & Canada)')
  end

  test 'can parse from date' do
    assert_equal '2012-07-01', format_date(Date.new(2012, 7, 1), 'Pacific Time (US & Canada)')
  end

  test 'can remove milliseconds from date time' do
    assert_equal '2012-07-01T12:55:44', truncate_millis('2012-07-01T12:55:44.611Z')
  end

  test 'can get current time depending of time zone' do
    current_time_fiji = current_time('Pacific/Fiji')
    utc_offset_fiji = '+1200'

    assert_equal utc_offset_fiji, current_time_fiji.strftime('%z')
  end
end
