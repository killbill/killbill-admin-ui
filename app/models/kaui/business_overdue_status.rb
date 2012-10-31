class Kaui::BusinessOverdueStatus < Kaui::Base
  define_attr :object_type
  define_attr :id
  define_attr :account_key
  define_attr :status
  define_attr :start_date
  define_attr :end_date
end