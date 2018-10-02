class Kaui::Base

  def self.to_money(amount, currency)
    begin
      return Money.from_amount(amount.to_f, currency)
    rescue => _
    end if currency.present?
    Money.from_amount(amount.to_f, 'USD')
  end
end
