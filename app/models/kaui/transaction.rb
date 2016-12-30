class Kaui::Transaction < KillBillClient::Model::Transaction

  attr_accessor :next_retry_date

  def self.build_from_raw_transaction(raw_transaction)
    result = Kaui::Transaction.new
    KillBillClient::Model::PaymentTransactionAttributes.instance_variable_get('@json_attributes').each do |attr|
      result.send("#{attr}=", raw_transaction.send(attr))
    end
    result
  end

  def create(account_id = nil, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
    if transaction_type == 'AUTHORIZE'
      auth(account_id, payment_method_id, user, reason, comment, options)
    elsif transaction_type == 'CAPTURE'
      capture(user, reason, comment, options)
    elsif transaction_type == 'CHARGEBACK'
      chargeback(user, reason, comment, options)
    elsif transaction_type == 'CREDIT'
      credit(account_id, payment_method_id, user, reason, comment, options)
    elsif transaction_type == 'PURCHASE'
      purchase(account_id, payment_method_id, user, reason, comment, options)
    elsif transaction_type == 'REFUND'
      refund(user, reason, comment, options)
    elsif transaction_type == 'VOID'
      void(user, reason, comment, options)
    else
      raise ArgumentError.new("Unknown transaction type #{transaction_type}")
    end
  end

  def amount_to_money
    Kaui::Base.to_money(amount, currency)
  end

  def self.amount_to_money(transaction)
    self.new(:amount => transaction.amount, :currency => transaction.currency).amount_to_money
  end
end
