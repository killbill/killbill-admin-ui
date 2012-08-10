require 'active_model'

class Kaui::Refund < Kaui::Base
  SAMPLE_REASON_CODES = [ "500 - Courtesy",
                          "501 - Billing Error",
                          "502 - Alt payment method",
                          "599 - OTHER" ]

  define_attr :refund_id
  define_attr :payment_id
  define_attr :adjusted
  define_attr :refund_amount
  define_attr :requested_dt
  define_attr :effective_dt

  has_many :audit_logs, Kaui::AuditLog

  def initialize(data = {})
    super(:refund_id => data['refundId'] || data['refund_id'],
          :payment_id => data['paymentId'] || data['payment_id'],
          :adjusted => data['adjusted'],
          :refund_amount => data['refundAmount'] || data['refund_amount'],
          :requested_dt => data['requestedDate'] || data['requested_date'] || data['requested_dt'],
          :effective_dt => data['effectiveDate'] || data['effective_date'] || data['effective_dt'],
          :audit_logs => data['auditLogs'])
  end
end