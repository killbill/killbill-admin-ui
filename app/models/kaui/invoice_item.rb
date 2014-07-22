class Kaui::InvoiceItem < KillBillClient::Model::InvoiceItem

  SAMPLE_REASON_CODES = ['100 - Courtesy',
                         '101 - Billing Error',
                         '199 - OTHER']

  def amount_to_money
    Kaui::Base.to_money(amount, currency)
  end

  def self.amount_to_money(invoice_item)
    self.new(:amount => invoice_item.amount, :currency => invoice_item.currency).amount_to_money
  end
end
