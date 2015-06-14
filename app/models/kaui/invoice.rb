class Kaui::Invoice < KillBillClient::Model::Invoice

  def initialize(raw_invoice)
    # There is probably a meta-programming trick to avoid writing that copy ctor by hand...
    @amount = raw_invoice.amount
    @currency = raw_invoice.currency
    @credit_adj = raw_invoice.credit_adj
    @refund_adj = raw_invoice.refund_adj
    @invoice_id = raw_invoice.invoice_id
    @invoice_date = raw_invoice.invoice_date
    @target_date = raw_invoice.target_date
    @invoice_number = raw_invoice.invoice_number
    @balance = raw_invoice.balance
    @account_id = raw_invoice.account_id
    @external_bundle_keys = raw_invoice.external_bundle_keys
    @credits = raw_invoice.credits
    @items = raw_invoice.items
    @audit_logs = raw_invoice.audit_logs
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
