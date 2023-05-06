# frozen_string_literal: true

require 'test_helper'

module Kaui
  class InvoiceTest < ActiveSupport::TestCase
    test 'can convert to money' do
      invoice = Kaui::Invoice.new(amount: 12.42, balance: 54.32, refund_adj: 48, credit_adj: 1.2, currency: 'USD')

      assert_equal 1242, invoice.amount_to_money.cents
      assert_equal 'USD', invoice.amount_to_money.currency.to_s

      assert_equal 5432, invoice.balance_to_money.cents
      assert_equal 'USD', invoice.balance_to_money.currency.to_s

      assert_equal 4800, invoice.refund_adjustment_to_money.cents
      assert_equal 'USD', invoice.refund_adjustment_to_money.currency.to_s

      assert_equal 120, invoice.credit_adjustment_to_money.cents
      assert_equal 'USD', invoice.credit_adjustment_to_money.currency.to_s
    end
  end
end
