# frozen_string_literal: true

require 'test_helper'

module Kaui
  class BaseTest < ActiveSupport::TestCase
    test 'can convert to money' do
      # Happy path
      %w[GBP MXN BRL EUR AUD USD CAD].each do |currency|
        money = Kaui::Base.to_money(12.42, currency)
        assert_equal 1242, money.cents
        assert_equal currency, money.currency.iso_code
      end
      %w[JPY KRW].each do |currency|
        money = Kaui::Base.to_money(12, currency)
        assert_equal 12, money.cents
        assert_equal currency, money.currency.iso_code
      end

      # Edge cases
      bad_money = Kaui::Base.to_money(12.42, 'blahblah')
      assert_equal 1242, bad_money.cents
      assert_equal 'USD', bad_money.currency.iso_code
    end
  end
end
