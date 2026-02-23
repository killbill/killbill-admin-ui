# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountHelperTest < ActionView::TestCase
    test 'effective_bcd returns account BCD when no bundles' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)
      assert_equal 30, effective_bcd(account, nil)
    end

    test 'effective_bcd returns account BCD when bundles are empty' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)
      assert_equal 30, effective_bcd(account, [])
    end

    test 'effective_bcd returns subscription BCD when subscription has BCD set' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      subscription = Kaui::Subscription.new
      subscription.bill_cycle_day_local = 5
      subscription.state = 'ACTIVE'

      bundle = Kaui::Bundle.new
      bundle.subscriptions = [subscription]

      assert_equal 5, effective_bcd(account, [bundle])
    end

    test 'effective_bcd returns account BCD when subscription BCD is 0' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      subscription = Kaui::Subscription.new
      subscription.bill_cycle_day_local = 0
      subscription.state = 'ACTIVE'

      bundle = Kaui::Bundle.new
      bundle.subscriptions = [subscription]

      assert_equal 30, effective_bcd(account, [bundle])
    end

    test 'effective_bcd returns account BCD when subscription BCD is nil' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      subscription = Kaui::Subscription.new
      subscription.bill_cycle_day_local = nil
      subscription.state = 'ACTIVE'

      bundle = Kaui::Bundle.new
      bundle.subscriptions = [subscription]

      assert_equal 30, effective_bcd(account, [bundle])
    end

    test 'effective_bcd ignores cancelled subscriptions' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      subscription = Kaui::Subscription.new
      subscription.bill_cycle_day_local = 5
      subscription.state = 'CANCELLED'

      bundle = Kaui::Bundle.new
      bundle.subscriptions = [subscription]

      assert_equal 30, effective_bcd(account, [bundle])
    end

    test 'effective_bcd returns first active subscription BCD' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      cancelled_subscription = Kaui::Subscription.new
      cancelled_subscription.bill_cycle_day_local = 10
      cancelled_subscription.state = 'CANCELLED'

      active_subscription = Kaui::Subscription.new
      active_subscription.bill_cycle_day_local = 5
      active_subscription.state = 'ACTIVE'

      bundle = Kaui::Bundle.new
      bundle.subscriptions = [cancelled_subscription, active_subscription]

      assert_equal 5, effective_bcd(account, [bundle])
    end

    test 'effective_bcd checks multiple bundles' do
      account = Kaui::Account.new(bill_cycle_day_local: 30)

      # First bundle has no active subscription with BCD
      subscription1 = Kaui::Subscription.new
      subscription1.bill_cycle_day_local = 0
      subscription1.state = 'ACTIVE'

      bundle1 = Kaui::Bundle.new
      bundle1.subscriptions = [subscription1]

      # Second bundle has active subscription with BCD
      subscription2 = Kaui::Subscription.new
      subscription2.bill_cycle_day_local = 5
      subscription2.state = 'ACTIVE'

      bundle2 = Kaui::Bundle.new
      bundle2.subscriptions = [subscription2]

      assert_equal 5, effective_bcd(account, [bundle1, bundle2])
    end
  end
end
