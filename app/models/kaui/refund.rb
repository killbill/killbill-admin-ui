class Kaui::Refund < Kaui::Base
  SAMPLE_REASON_CODES = [ "500 - Courtesy",
                   "501 - Billing Error",
                   "502 - Alt payment method", 
                   "599 - OTHER" ]

  define_attr :account_id
  define_attr :external_key
  define_attr :payment_id
  define_attr :invoice_id
  define_attr :amount
  define_attr :comment
  define_attr :reason
end