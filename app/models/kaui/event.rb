class Kaui::Event < Kaui::Base
  define_attr :event_id
  define_attr :billing_period
  define_attr :effective_dt
  define_attr :event_type
  define_attr :phase
  define_attr :price_list
  define_attr :product
  define_attr :requested_dt

  has_many :audit_logs, Kaui::AuditLog

  def initialize(data = {})
    super(:event_id => data['eventId'],
          :billing_period => data['billingPeriod'],
          :effective_dt => data['effectiveDate'],
          :event_type => data['eventType'],
          :phase => data['phase'],
          :price_list => data['priceList'],
          :product => data['product'],
          :requested_dt => data['requestedDate'],
          :audit_logs => data['auditLogs'])
  end
end
