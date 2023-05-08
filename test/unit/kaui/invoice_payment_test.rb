# frozen_string_literal: true

require 'test_helper'

module Kaui
  class InvoicePaymentTest < ActiveSupport::TestCase
    test 'can convert to money' do
      payment = Kaui::InvoicePayment.new(auth_amount: 12.42,
                                         captured_amount: 10.2,
                                         purchased_amount: 12,
                                         refunded_amount: 9,
                                         credited_amount: 5,
                                         currency: 'USD')

      assert_equal 1242, payment.auth_amount_to_money.cents
      assert_equal 'USD', payment.auth_amount_to_money.currency.to_s

      assert_equal 1020, payment.captured_amount_to_money.cents
      assert_equal 'USD', payment.captured_amount_to_money.currency.to_s

      assert_equal 1200, payment.purchased_amount_to_money.cents
      assert_equal 'USD', payment.purchased_amount_to_money.currency.to_s

      assert_equal 900, payment.refunded_amount_to_money.cents
      assert_equal 'USD', payment.refunded_amount_to_money.currency.to_s

      assert_equal 500, payment.credited_amount_to_money.cents
      assert_equal 'USD', payment.credited_amount_to_money.currency.to_s

      assert_equal 2220, payment.paid_amount_to_money.cents
      assert_equal 'USD', payment.paid_amount_to_money.currency.to_s

      assert_equal 1400, payment.returned_amount_to_money.cents
      assert_equal 'USD', payment.returned_amount_to_money.currency.to_s
    end

    test 'can check for full refunds' do
      assert Kaui::InvoicePayment.new(purchased_amount: 10.2, refunded_amount: 10.20, currency: 'USD').fully_refunded?
      assert !Kaui::InvoicePayment.new(purchased_amount: 10.2, refunded_amount: 9, currency: 'USD').fully_refunded?

      assert Kaui::InvoicePayment.new(captured_amount: 10.2, refunded_amount: 10.20, currency: 'USD').fully_refunded?
      assert !Kaui::InvoicePayment.new(captured_amount: 10.2, refunded_amount: 9, currency: 'USD').fully_refunded?
    end
  end
end
