require 'active_model'

class Kaui::PaymentAttempt < Kaui::Base
  define_attr :account_id
  define_attr :invoice_id
  define_attr :amount
  define_attr :currency
  define_attr :payment_id
  define_attr :payment_attempt_id
  define_attr :payment_attempt_date
  define_attr :invoice_dt
  define_attr :created_dt
  define_attr :udpated_dt
  define_attr :retry_count

  def initialize(data = {})
    super(:account_id => data['accountId'],
          :invoice_id => data['invoiceId'],
          :amount => data['amount'],
          :currency => data['currency'],
          :payment_id => data['paymentId'],
          :payment_attempt_id => data['paymentAttemptId'],
          :payment_attempt_date => data['paymentAttemptDate'],
          :invoice_dt => data['invoiceDate'],
          :created_dt => data['createdDate'],
          :udpated_dt => data['updatedDate'],
          :retry_count => data['retryCount'])
  end
end