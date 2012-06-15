require 'active_model'

class Kaui::Account < Kaui::Base
  define_attr :account_id
  define_attr :external_key
  define_attr :name
  define_attr :first_name_length
  define_attr :email
  define_attr :billing_day
  define_attr :currency
  define_attr :timezone
  define_attr :address1
  define_attr :address2
  define_attr :company
  define_attr :state
  define_attr :country
  define_attr :phone

  def initialize(data = {})
    super(:account_id => data['accountId'],
          :external_key => data['externalKey'],
          :name => data['name'] || "#{data['firstName'] || ''}#{data.has_key?('firstName') ? ' ' : ''}#{data['lastName'] || ''}",
          :first_name_length => data['length'] || (data.has_key?('firstName') ? data['firstName'].length : 0),
          :email => data['email'],
          :billing_day => data['billingDay'],
          :currency => data['currency'],
          :timezone => data['timeZone'] || data['timezone'],
          :address1 => data['address1'],
          :address2 => data['address2'],
          :company =>  data['company'],
          :state => data['state'],
          :country => data['country'],
          :phone => data['phone'])
  end
end
