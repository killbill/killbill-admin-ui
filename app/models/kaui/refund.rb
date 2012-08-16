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
  define_attr :requested_date
  define_attr :effective_date
  define_attr :adjustments

  has_many :audit_logs, Kaui::AuditLog
end