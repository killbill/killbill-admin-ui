# frozen_string_literal: true

module Kaui
  module PaymentState
    def refundable?
      transactions.each do |transaction|
        return true if transaction.status == 'SUCCESS' && %w[CAPTURE PURCHASE].include?(transaction.transaction_type)
      end
      false
    end

    def amount_refundable
      captured_amount + purchased_amount - refunded_amount
    end

    def amount_capturable
      auth_amount - captured_amount
    end

    def capturable?
      maybe = false
      transactions.each do |transaction|
        next unless transaction.status == 'SUCCESS'
        return false if transaction.transaction_type == 'VOID'

        maybe = true if transaction.transaction_type == 'AUTHORIZE'
      end
      maybe && refunded_amount.zero?
    end

    def voidable?
      transactions.each do |transaction|
        return false if transaction.status == 'SUCCESS' && transaction.transaction_type == 'VOID'
      end
      capturable? && captured_amount.zero?
    end

    def chargebackable?
      refundable?
    end

    def total_authed_amount_to_money
      auth_amount_to_money + purchased_amount_to_money
    end

    def paid_amount_to_money
      captured_amount_to_money + purchased_amount_to_money
    end

    # TODO: Better name?
    def returned_amount_to_money
      refunded_amount_to_money + credited_amount_to_money
    end

    def fully_refunded?
      refunded_amount == captured_amount || refunded_amount == purchased_amount
    end
  end
end
