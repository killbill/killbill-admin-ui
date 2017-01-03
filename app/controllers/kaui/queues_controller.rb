class Kaui::QueuesController < Kaui::EngineController

  def index
    @account_id = params[:account_id]
    @now = Kaui::Admin.get_clock(nil, options_for_klient)['currentUtcTime'].to_datetime

    min_date = params[:min_date]
    with_history = params[:with_history] || false
    @queues_entries = Kaui::Admin.get_queues_entries(@account_id, options_for_klient.merge(:withHistory => with_history, :minDate => min_date))
  end
end
