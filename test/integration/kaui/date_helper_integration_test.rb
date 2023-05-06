# frozen_string_literal: true

require 'test_helper'

module Kaui
  class DateHelperIntegrationTest < IntegrationTestHelper
    include Kaui::DateHelper

    test 'can get killbill server current time depending of time zone' do
      current_time_fiji = current_time('America/Puerto_Rico', options)
      utc_offset_fiji = '-0400'

      assert_equal utc_offset_fiji, current_time_fiji.strftime('%z')
    end
  end
end
