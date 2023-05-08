# frozen_string_literal: true

module Kaui
  class InvoicePayment < KillBillClient::Model::InvoicePayment
    include Kaui::PaymentState

    class << self
      def find_safely_by_id(id, options = {})
        Kaui::InvoicePayment.find_by_id(id, true, true, options)
      rescue StandardError => e
        # Maybe the plugin is not registered or the plugin threw an exception
        Rails.logger.warn(e)
        Kaui::InvoicePayment.find_by_id(id, false, true, options)
      end

      def build_from_raw_payment(raw_payment)
        return nil if raw_payment.nil?

        result = Kaui::InvoicePayment.new
        KillBillClient::Model::InvoicePaymentAttributes.instance_variable_get('@json_attributes').each do |attr|
          result.send("#{attr}=", raw_payment.send(attr))
        end
        # Use  Kaui::Transaction to benefit from additional fields (e.g next_retry_date)
        original_transactions = (result.transactions || [])
        result.transactions = []
        original_transactions.each do |transaction|
          new_transaction = Kaui::Transaction.new
          KillBillClient::Model::PaymentTransactionAttributes.instance_variable_get('@json_attributes').each do |attr|
            new_transaction.send("#{attr}=", transaction.send(attr))
          end
          result.transactions << new_transaction
        end
        result.build_transactions_next_retry_date!
        result
      end
    end

    %i[auth captured purchased refunded credited].each do |type|
      define_method "#{type}_amount_to_money" do
        Kaui::Base.to_money(send("#{type}_amount"), currency)
      end
    end

    # For each payment transaction, compute next_retry date by joining with payment attempts
    def build_transactions_next_retry_date!
      # Filter scheduled attempts: We could have several in parallel when multiple independent transactions occur at the same time
      # (They would have different transaction_external_key)
      scheduled_attempts = (payment_attempts || []).select do |a|
        a.state_name == 'SCHEDULED'
      end

      # Look for latest transaction associated with each such scheduled attempt and set retry date accordingly
      scheduled_attempts.each do |a|
        last_transaction_for_attempt = (transactions || []).select do |t|
          t.transaction_external_key == a.transaction_external_key
        end.max_by(&:effective_date)

        last_transaction_for_attempt.next_retry_date = a.effective_date if last_transaction_for_attempt
      end
    end
  end
end
