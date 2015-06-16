class Kaui::Invoice < KillBillClient::Model::Invoice

  def self.build_from_raw_invoice(raw_invoice)
    # There is probably a meta-programming trick to avoid writing that copy ctor by hand...
    result = Kaui::Invoice.new
    result.amount = raw_invoice.amount
    result.currency = raw_invoice.currency
    result.credit_adj = raw_invoice.credit_adj
    result.refund_adj = raw_invoice.refund_adj
    result.invoice_id = raw_invoice.invoice_id
    result.invoice_date = raw_invoice.invoice_date
    result.target_date = raw_invoice.target_date
    result.invoice_number = raw_invoice.invoice_number
    result.balance = raw_invoice.balance
    result.account_id = raw_invoice.account_id
    result.external_bundle_keys = raw_invoice.external_bundle_keys
    result.credits = raw_invoice.credits
    result.items = raw_invoice.items
    result.audit_logs = raw_invoice.audit_logs
    result
  end


  [:amount, :balance, :credits].each do |type|
    define_method "#{type}_to_money" do
      Kaui::Base.to_money(send(type), currency)
    end
  end

  def refund_adjustment_to_money
    Kaui::Base.to_money(refund_adj, currency)
  end

  def credit_adjustment_to_money
    Kaui::Base.to_money(credit_adj, currency)
  end
end
