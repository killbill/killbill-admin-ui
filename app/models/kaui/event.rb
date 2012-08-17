class Kaui::Event < Kaui::Base
  define_attr :event_id
  define_attr :billing_period
  define_attr :effective_date
  define_attr :event_type
  define_attr :phase
  define_attr :price_list
  define_attr :product
  define_attr :requested_date

  has_many :audit_logs, Kaui::AuditLog

end
