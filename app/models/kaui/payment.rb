require 'active_model'

class Kaui::Payment < Kaui::Base

  SAMPLE_REASON_CODES = [ "600 - Alt payment method",
                          "699 - OTHER" ]

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
  has_many :audit_logs, Kaui::AuditLog

  def initialize(data = {})
    super(:account_id => data['accountId'] || data['account_id'],
          :amount => data['amount'],
          :currency => data['currency'],
          :effective_dt => data['effectiveDate'] || data['effective_dt'],
          :invoice_id => data['invoiceId'] || data['invoice_id'],
          :paid_amount => data['paidAmount'] || data['paid_amount'],
          :payment_id => data['paymentId'] || data['payment_id'],
          :payment_method_id => data['paymentMethodId'] || data['payment_method_id'],
          :refund_amount => data['refundAmount'] || data['refund_amount'],
          :requested_dt => data['requestedDate'] || data['requested_dt'],
          :retry_count => data['retryCount'] || data['retry_count'],
          :status => data['status'],
          :bundle_keys => data['bundleKeys'] || data['bundle_keys'],
          :refunds => data['refunds'],
          :chargebacks => data['chargebacks'],
          :audit_logs => data['auditLogs'])
  end
end