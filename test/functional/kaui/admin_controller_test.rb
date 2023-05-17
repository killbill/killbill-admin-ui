# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AdminControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index
      clock = retrieve_date
      assert_not_nil clock
      date = DateTime.parse(clock.to_s.gsub('"', '')).strftime('%F')
      assert_match(/\d{4}-\d{,2}-\d{,2}/, date)
      assert_response :success
    end

    test 'should set clock' do
      # retrieve current clock from killbill
      get :index

      clock = retrieve_date
      assert_not_nil clock
      date = DateTime.parse(clock.to_s.gsub('"', '')).strftime('%F')
      assert_match(/\d{4}-\d{,2}-\d{,2}/, date)
      assert_response :success

      # update killbill clock
      put :set_clock, params: { commit: 'Submit', new_date: clock }
      assert_response :redirect
      assert_equal I18n.translate('flashes.notices.clock_updated_successfully', new_date: date), flash[:notice]

      # reset killbill clock
      put :set_clock, params: { commit: nil }
      assert_response :redirect
    end

    private

    def retrieve_date
      return nil if @response.nil? || @response.body.nil?

      pattern = Regexp.new('<span.id="kb_clock">(?<clock>.+?)</span>')
      data = pattern.match(@response.body)
      data.nil? ? nil : data[:clock]
    end
  end
end
