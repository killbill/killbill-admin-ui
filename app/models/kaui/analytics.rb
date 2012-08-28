class Kaui::Analytics

  def self.accounts_over_time
    running_total(Kaui::KillbillHelper.get_accounts_created_over_time)
  end

  def self.subscriptions_over_time(product_type, slug)
    running_total(Kaui::KillbillHelper.get_subscriptions_created_over_time(product_type, slug))
  end

  # The analytics API returns the number of accounts created per day but we want to display a running total
  def self.running_total(per_day)
    total = []
    per_day.values.each_with_index do |value, idx|
      total << value + (idx == 0 ? 0 : total[idx - 1])
    end
    Kaui::TimeSeriesData.new(:dates => per_day.dates, :values => total)
  end
end