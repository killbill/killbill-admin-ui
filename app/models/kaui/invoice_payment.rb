class Kaui::InvoicePayment < KillBillClient::Model::InvoicePayment

  include Kaui::PaymentState

  SAMPLE_REASON_CODES = ['600 - Alt payment method',
                         '699 - OTHER']

  class << self

    def find_safely_by_id(id, options = {})
      Kaui::InvoicePayment.find_by_id(id, true, true, options)
    rescue => e
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

  [:auth, :captured, :purchased, :refunded, :credited].each do |type|
    define_method "#{type}_amount_to_money" do
      Kaui::Base.to_money(send("#{type}_amount"), currency)
    end


    # For each payment transaction, compute next_retry date by joining with payment attempts
    def build_transactions_next_retry_date!
      (transactions || []).each do |transaction|
        # Filter attempts matching that transaction and SCHEDULED for retry
        transaction.next_retry_date = (payment_attempts || []).select do |attempt|
          ((attempt.transaction_id && attempt.transaction_id == transaction.transaction_id) ||
              (attempt.transaction_external_key && attempt.transaction_external_key == transaction.transaction_external_key)) &&
              attempt.state_name == 'SCHEDULED'
        end.map do |attempt|
          attempt.effective_date
        end.first
      end
    end

  end
end
