class Kaui::QueuesController < Kaui::EngineController

  def index
    @account_id = params[:account_id]
    @queues_entries = Kaui::Admin.get_queues_entries(@account_id, options_for_klient)
  end
end
