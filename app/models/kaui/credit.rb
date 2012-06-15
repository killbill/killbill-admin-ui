class Kaui::Credit < Kaui::Base
  SAMPLE_REASON_CODES = [ "100 - Courtesy",
                   "101 - Billing Error",
                   "199 - OTHER" ]

  define_attr :account_id
  define_attr :invoice_id
  define_attr :amount
  define_attr :comment
  define_attr :reason
end