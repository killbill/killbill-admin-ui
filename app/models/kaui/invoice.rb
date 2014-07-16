class Kaui::Invoice < KillBillClient::Model::Invoice

  [:amount, :balance].each do |type|
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
