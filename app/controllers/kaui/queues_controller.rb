class Kaui::QueuesController < Kaui::EngineController

  def index
    @account_id = params[:account_id]
    begin
      @now = Kaui::Admin.get_clock(nil, options_for_klient)['currentUtcTime'].to_datetime
    rescue KillBillClient::API::NotFound
      # If TestResource is not bound, then clock has not been manipulated, we can default to NOW
      @now = DateTime.now.in_time_zone("UTC")
    end

    min_date = params[:min_date] || '1970-01-01'
    max_date = params[:max_date] || '2100-01-01'
    with_history = params[:with_history] || false
    @queues_entries = Kaui::Admin.get_queues_entries(@account_id, options_for_klient.merge(:withHistory => with_history, :minDate => min_date, :maxDate => max_date))

    params.permit!
  end
end
