class Kaui::ExternalPayment < Kaui::Base

  SAMPLE_REASON_CODES = [ "600 - Alt payment method",
                          "699 - OTHER" ]

  define_attr :amount
  define_attr :invoice_id
  define_attr :account_id

  def initialize(data = {})
    super(:amount => data['amount'],
          :invoice_id => data['invoiceId'] || data['invoice_id'],
          :account_id => data['accountId'] || data['account_id'])
  end
end