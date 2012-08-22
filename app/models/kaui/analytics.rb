class Kaui::Analytics

  def self.accounts_over_time
    # Sample data for now - we assume the data to be sorted
    {
      :dates  => ['2012-01', '2012-02', '2012-03', '2012-04', '2012-05', '2012-06'],
      :values => [ 10, 25, 50, 100, 200, 400]
    }
  end

end