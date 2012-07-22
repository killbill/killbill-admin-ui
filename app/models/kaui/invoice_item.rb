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
    super(
          :account_id => data['accountId'],
          :amount => data['amount'],
          :bundle_id => data['bundleId'],
          :currency => data['currency'],
          :description => data['description'],
          :end_date => data['endDate'],
          :invoice_id => data['invoiceId'],
          :phase_name => data['phaseName'],
          :plan_name => data['planName'],
          :start_date => data['startDate'],
          :subscription_id => data['subscriptionId'])
  end
end