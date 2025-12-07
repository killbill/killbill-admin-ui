# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AdminControllerTest < Kaui::FunctionalTestHelper
    test 'should set clock with valid date' do
      new_date = '2025-12-08'

      put :set_clock, params: { commit: 'Submit', new_date: new_date }

      assert_response :redirect
      assert_redirected_to admin_path
      assert_equal I18n.translate('flashes.notices.clock_updated_successfully', new_date: new_date), flash[:notice]
    end

    test 'should reset clock' do
      put :set_clock, params: { commit: 'Reset' }

      assert_response :redirect
      assert_redirected_to admin_path
      assert_equal I18n.translate('flashes.notices.clock_reset_successfully'), flash[:notice]
    end
  end
end
