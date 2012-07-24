require 'active_model'

class Kaui::Payment < Kaui::Base
  define_attr :account_id
  define_attr :amount
  define_attr :currency
  define_attr :invoice_id
  define_attr :effective_dt
  define_attr :paid_amount
  define_attr :payment_id
  define_attr :payment_method_id
  define_attr :refund_amount
  define_attr :requested_dt
  define_attr :retry_count
  define_attr :status
  define_attr :bundle_keys

  has_many :refunds, Kaui::Refund
  has_many :chargebacks, Kaui::Chargeback

  def initialize(data = {})
    super(:account_id => data['accountId'],
          :amount => data['amount'],
          :currency => data['currency'],
          :effective_dt => data['effectiveDate'],
          :invoice_id => data['invoiceId'],
          :paid_amount => data['paidAmount'],
          :payment_id => data['paymentId'],
          :payment_method_id => data['paymentMethodId'],
          :refund_amount => data['refundAmount'],
          :requested_dt => data['requestedDate'],
          :retry_count => data['retryCount'],
          :status => data['status'],
          :bundle_keys => data['bundleKeys'],
          :refunds => data['refunds'],
          :chargebacks => data['chargebacks'])
  end
end