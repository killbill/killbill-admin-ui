class Kaui::Invoice < KillBillClient::Model::Invoice


  def amount_to_money(currency)
    Kaui::Base.to_money(amount, currency)
  end

  def balance_to_money(currency)
    Kaui::Base.to_money(balance, currency)
  end

  def payment_amount_to_money(currency)
    Kaui::Base.to_money(payment_amount, currency)
  end

  def refund_adjustment_to_money(currency)
    Kaui::Base.to_money(refund_adjustment, currency)
  end

  def credit_balance_adjustment_to_money(currency)
    Kaui::Base.to_money(credit_balance_adjustment, currency)
  end

  def credit_adjustment_to_money(currency)
    Kaui::Base.to_money(credit_adjustment, currency)
  end
end
