require 'active_model'

class Kaui::InvoiceItem < Kaui::Base
  define_attr :invoice_id
  define_attr :account_id
  define_attr :bundle_id
  define_attr :subscription_id
  define_attr :plan_name
  define_attr :phase_name
  define_attr :description
  define_attr :start_date
  define_attr :end_date
  define_attr :amount;
  define_attr :currency;

  def initialize(data = {})
    super(:invoice_id => data['invoiceId'],
          :account_id => data['accountId'],
          :bundle_id => data['bundleId'],
          :subscription_id => data['subscriptionId'],
          :plan_name => data['planName'],
          :phase_name => data['phaseName'],
          :description => data['description'],
          :start_date => data['startDate'],
          :end_date => data['endDate'],
          :amount => data['amount'],
          :currency => data['currency'])
  end
end