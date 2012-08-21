require 'active_model'

class Kaui::Payment < Kaui::Base

  SAMPLE_REASON_CODES = [ "600 - Alt payment method",
                          "699 - OTHER" ]

  define_attr :account_id
  define_attr :amount
  define_attr :currency
  define_attr :invoice_id
  define_attr :effective_date
  define_attr :paid_amount
  define_attr :payment_id
  define_attr :payment_method_id
  define_attr :refund_amount
  define_attr :requested_date
  define_attr :retry_count
  define_attr :status
  define_attr :bundle_keys
  define_attr :ext_first_payment_id_ref
  define_attr :ext_second_payment_id_ref
  define_attr :gateway_error_code
  define_attr :gateway_error_msg
  define_attr :external

  has_many :refunds, Kaui::Refund
  has_many :chargebacks, Kaui::Chargeback
  has_many :audit_logs, Kaui::AuditLog
end