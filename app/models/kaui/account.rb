require 'active_model'

class Kaui::Account < Kaui::Base
  define_attr :account_id
  define_attr :external_key
  define_attr :name
  define_attr :first_name_length
  define_attr :email
  define_attr :currency
  define_attr :payment_method_id
  define_attr :timezone
  define_attr :address1
  define_attr :address2
  define_attr :company
  define_attr :state
  define_attr :country
  define_attr :phone
  define_attr :balance
  define_attr :is_notified_for_invoices
  has_one :bill_cycle_day, Kaui::BillCycleDay

  def initialize(data = {})
    super(:account_id => data['accountId'],
          :external_key => data['externalKey'],
          :name => data['name'] || "#{data['firstName'] || ''}#{data.has_key?('firstName') ? ' ' : ''}#{data['lastName'] || ''}",
          :first_name_length => data['length'] || (data.has_key?('firstName') ? data['firstName'].length : 0),
          :email => data['email'],
          :currency => data['currency'],
          :payment_method_id => data['paymentMethodId'],
          :timezone => data['timeZone'] || data['time_zone'] || data['timezone'],
          :address1 => data['address1'],
          :address2 => data['address2'],
          :company =>  data['company'],
          :state => data['state'],
          :country => data['country'],
          :phone => data['phone'],
          :bill_cycle_day => data['billCycleDay'],
          :balance => data['accountBalance'],
          :is_notified_for_invoices => data['isNotifiedForInvoices'])
  end

  def to_param
    @account_id
  end

  def balance_to_money
    Kaui::Base.to_money(balance.abs, currency)
  end
end
