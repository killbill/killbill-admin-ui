class Kaui::Invoice < KillBillClient::Model::Invoice

  def amount_to_money
    Kaui::Base.to_money(amount, currency)
  end

  def balance_to_money
    Kaui::Base.to_money(balance, currency)
  end

  def refund_adjustment_to_money
    Kaui::Base.to_money(refund_adj, currency)
  end

  def credit_adjustment_to_money
    Kaui::Base.to_money(credit_adj, currency)
  end
end
