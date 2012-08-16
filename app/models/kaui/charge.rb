class Kaui::Charge < Kaui::Base

  define_attr :account_id
  define_attr :invoice_id
  define_attr :amount
  define_attr :description

  def initialize(data = {})
    super(:account_id => data['accountId'] || data['account_id'],
          :invoice_id => data['invoiceId'] || data['invoice_id'],
          :amount => data['amount'],
          :description => data['description'])
  end
end