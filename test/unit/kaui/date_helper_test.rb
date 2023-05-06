# frozen_string_literal: true

require 'test_helper'

module Kaui
  class DateHelperTest < ActiveSupport::TestCase
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
      utc_offset_fiji_without_saving_time = '+1200'
      utc_offset_fiji_with_saving_time = '+1300'

      assert_includes [utc_offset_fiji_with_saving_time, utc_offset_fiji_without_saving_time], current_time_fiji.strftime('%z')
    end
  end
end
