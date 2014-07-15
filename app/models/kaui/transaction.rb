class Kaui::Transaction < KillBillClient::Model::Transaction

  def amount_to_money
    Kaui::Base.to_money(amount, currency)
  end

  def self.amount_to_money(transaction)
    self.new(:amount => transaction.amount, :currency => transaction.currency).amount_to_money
  end
end
