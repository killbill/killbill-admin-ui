require 'active_model'

class Kaui::InvoiceItem < Kaui::Base
  SAMPLE_REASON_CODES = [ "100 - Courtesy",
                          "101 - Billing Error",
                          "199 - OTHER" ]

  define_attr :invoice_item_id
  define_attr :invoice_id
  define_attr :account_id
  define_attr :bundle_id
  define_attr :subscription_id
  define_attr :plan_name
  define_attr :phase_name
  define_attr :description
  define_attr :start_date
  define_attr :end_date
  define_attr :amount;
  define_attr :currency;
  define_attr :audit_logs;
end