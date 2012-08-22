class Kaui::Analytics

  def self.accounts_over_time
    accounts_created_per_day = Kaui::KillbillHelper.get_accounts_created_over_time
    # The analytics API returns the number of accounts created per day but we want to display a running total
    total = []
    accounts_created_per_day.values.each_with_index do |value, idx|
      total << value + (idx == 0 ? 0 : total[idx - 1])
    end
    Kaui::TimeSeriesData.new(:dates => accounts_created_per_day.dates, :values => total)
  end

end