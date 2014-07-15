class Kaui::Account < KillBillClient::Model::Account

  def balance_to_money
    Kaui::Base.to_money(account_balance.abs, currency)
  end

  def cba_to_money
    Kaui::Base.to_money(account_cba.abs, currency)
  end
end
