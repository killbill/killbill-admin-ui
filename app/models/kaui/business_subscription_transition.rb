class Kaui::BusinessSubscriptionTransition < Kaui::Base
  define_attr :total_ordering
  define_attr :bundle_id
  define_attr :external_key
  define_attr :account_id
  define_attr :account_key
  define_attr :subscription_id

  define_attr :requested_timestamp
  define_attr :event_type
  define_attr :category

  define_attr :prev_product_name
  define_attr :prev_product_type
  define_attr :prev_product_category
  define_attr :prev_slug
  define_attr :prev_phase
  define_attr :prev_billing_period
  define_attr :prev_price
  define_attr :prev_price_list
  define_attr :prev_mrr
  define_attr :prev_currency
  define_attr :prev_start_date
  define_attr :prev_state

  define_attr :next_product_name
  define_attr :next_product_type
  define_attr :next_product_category
  define_attr :next_slug
  define_attr :next_phase
  define_attr :next_billing_period
  define_attr :next_price
  define_attr :next_price_list
  define_attr :next_mrr
  define_attr :next_currency
  define_attr :next_start_date
  define_attr :next_state
end