class Kaui::OverdueState < Kaui::Base

  define_attr :name
  define_attr :external_message
  define_attr :days_between_payment_retries
  define_attr :disable_entitlement_and_changes_blocked
  define_attr :block_changes
  define_attr :clear_state
  define_attr :reevaluation_interval_days
end