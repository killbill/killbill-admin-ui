class Kaui::BusinessInvoice < Kaui::Base
  define_attr :invoice_id
  define_attr :invoice_number
  define_attr :account_id
  define_attr :account_key
  define_attr :invoice_date
  define_attr :target_date
  define_attr :currency
  define_attr :balance
  define_attr :amount_paid
  define_attr :amount_charged
  define_attr :amount_credited

  has_many :invoice_items, Kaui::BusinessInvoiceItem
end