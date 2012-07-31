class Kaui::Credit < Kaui::Base
  SAMPLE_REASON_CODES = [ "100 - Courtesy",
                          "101 - Billing Error",
                          "199 - OTHER" ]

  define_attr :account_id
  define_attr :invoice_id
  define_attr :credit_amount
  define_attr :requested_date
  define_attr :effective_date
  define_attr :comment
  define_attr :reason

  def initialize(data = {})
    super(:account_id => data['accountId'] || data['account_id'],
          :invoice_id => data['invoiceId'] || data['invoice_id'],
          :credit_amount => data['creditAmount'] || data['credit_amount'],
          :requested_date => data['requestedDate'] || data['requested_date'],
          :effective_date => data['effectiveDate'] || data['effective_date'])
  end
end