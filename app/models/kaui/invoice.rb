require 'active_model'

class Kaui::Invoice < Kaui::Base
  define_attr :amount
  define_attr :balance
  define_attr :invoice_id
  define_attr :account_id
  define_attr :invoice_number
  define_attr :payment_amount
  define_attr :invoice_dt
  define_attr :payment_dt
  define_attr :target_dt
  define_attr :bundle_keys
  has_many :items, Kaui::InvoiceItem

  def initialize(data = {})
    super(:amount => data['amount'],
          :balance => data['balance'],
          :invoice_id => data['invoiceId'],
          :account_id => data['accountId'],
          :invoice_number => data['invoiceNumber'],
          :payment_amount => data['paymentAmount'],
          :invoice_dt => data['invoiceDate'],
          :payment_dt => data['paymentDate'],
          :target_dt => data['targetDate'],
          :bundle_keys => data['bundleKeys'],
          :items => data['items'])
  end
end