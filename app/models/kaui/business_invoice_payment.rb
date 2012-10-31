class Kaui::BusinessInvoicePayment < Kaui::Base
  define_attr :payment_id
  define_attr :ext_first_payment_ref_id
  define_attr :ext_second_payment_ref_id
  define_attr :account_key
  define_attr :invoice_id
  define_attr :effective_date
  define_attr :amount
  define_attr :currency
  define_attr :payment_error
  define_attr :processing_status
  define_attr :requested_amount
  define_attr :plugin_name
  define_attr :payment_type
  define_attr :payment_method
  define_attr :card_type
  define_attr :card_country
  define_attr :invoice_payment_type
  define_attr :linked_invoice_payment_id
end