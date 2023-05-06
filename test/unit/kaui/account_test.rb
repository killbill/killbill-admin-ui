# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountTest < ActiveSupport::TestCase
    test 'can convert to money' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD')
      assert_equal 1242, account.balance_to_money.cents
      assert_equal 'USD', account.balance_to_money.currency.to_s

      assert_equal 5432, account.cba_to_money.cents
      assert_equal 'USD', account.cba_to_money.currency.to_s
    end

    test 'fail when phone is missing' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', bill_cycle_day_local: 1)
      assert_equal false, account.check_account_details_phone
    end

    test 'ok when phone is added' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '+1323323323', bill_cycle_day_local: 1)
      assert_equal true, account.check_account_details_phone
    end

    test 'ok when bililng cycle is added' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '+1323323323', bill_cycle_day_local: 31)
      assert_equal true, account.check_account_details_bill_cycle_day_local
    end

    test 'fail when bililng cycle is invalid' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '+1323323323', bill_cycle_day_local: 40)
      assert_equal false, account.check_account_details_bill_cycle_day_local
    end

    test 'fail when phone is short' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '1323', bill_cycle_day_local: 1)
      assert_equal false, account.check_account_details_phone
    end

    test 'ok when german phone number format' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '+49 211 1234567', bill_cycle_day_local: 1)
      assert_equal true, account.check_account_details_phone
    end

    test 'ok when phone number has enclosed the area code in parentheses fallowed by a nonbreaking space, and then hyphenate the three-digit exchange code with the four-digit number.' do
      account = Kaui::Account.new(account_balance: 12.42, account_cba: 54.32, currency: 'USD', phone: '(213) 156-7890', bill_cycle_day_local: 1)
      assert_equal true, account.check_account_details_phone
    end
  end
end
