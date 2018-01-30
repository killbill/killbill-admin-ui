class Kaui::Base

  def self.to_money(amount, currency)
    begin
      return Money.new(amount.to_f * 100, currency)
    rescue => _
    end if currency.present?
    Money.new(amount.to_f * 100, 'USD')
  end
end
