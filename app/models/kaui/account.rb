class Kaui::Account < KillBillClient::Model::Account

  def balance_to_money
    Kaui::Base.to_money(balance.abs, currency)
  end

  def cba_to_money
    Kaui::Base.to_money(cba.abs, currency)
  end
end
