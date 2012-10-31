class Kaui::BusinessInvoiceItem < Kaui::Base
  define_attr :item_id
  define_attr :invoice_id
  define_attr :item_type
  define_attr :external_key
  define_attr :product_name
  define_attr :product_type
  define_attr :product_category
  define_attr :slug
  define_attr :phase
  define_attr :billing_period
  define_attr :start_date
  define_attr :end_date
  define_attr :amount
  define_attr :currency
  define_attr :linked_item_id
end