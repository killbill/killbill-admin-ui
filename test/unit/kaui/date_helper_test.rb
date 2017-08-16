require 'test_helper'

class Kaui::DateHelperTest < ActiveSupport::TestCase

  include Kaui::DateHelper

  test 'can parse from string' do
    assert_equal '2012-07-01', format_date('2012-07-01T12:55:44Z', 'Pacific Time (US & Canada)')
  end

  test 'can parse from date' do
    assert_equal '2012-07-01', format_date(Date.new(2012, 7, 1), 'Pacific Time (US & Canada)')
  end
end
