# frozen_string_literal: true

module Kaui
  class Transaction < KillBillClient::Model::Transaction
    attr_accessor :next_retry_date

    def self.build_from_raw_transaction(raw_transaction)
      result = Kaui::Transaction.new
      KillBillClient::Model::PaymentTransactionAttributes.instance_variable_get('@json_attributes').each do |attr|
        result.send("#{attr}=", raw_transaction.send(attr))
      end
      result
    end

    def create(account_id = nil, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
      case transaction_type
      when 'AUTHORIZE'
        auth(account_id, payment_method_id, user, reason, comment, options)
      when 'CAPTURE'
        capture(user, reason, comment, options)
      when 'CHARGEBACK'
        chargeback(user, reason, comment, options)
      when 'CREDIT'
        credit(account_id, payment_method_id, user, reason, comment, options)
      when 'PURCHASE'
        purchase(account_id, payment_method_id, user, reason, comment, options)
      when 'REFUND'
        refund(user, reason, comment, options)
      when 'VOID'
        void(user, reason, comment, options)
      else
        raise ArgumentError, "Unknown transaction type #{transaction_type}"
      end
    end

    def amount_to_money
      Kaui::Base.to_money(amount, currency)
    end

    def processed_amount_to_money
      Kaui::Base.to_money(processed_amount, processed_currency)
    end

    def self.amount_to_money(transaction)
      new(amount: transaction.amount, currency: transaction.currency).amount_to_money
    end

    def self.processed_amount_to_money(transaction)
      new(processed_amount: transaction.processed_amount, processed_currency: transaction.processed_currency).processed_amount_to_money
    end
  end
end
