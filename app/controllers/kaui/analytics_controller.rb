module Kaui
  class AnalyticsController < Kaui::EngineController

    def index
    end

    def account_snapshot
      # params[:account_id] can either be a uuid or an external key
      begin
        @account = Kaui::KillbillHelper::get_account_by_key(params[:account_id], false, false, options_for_klient)
        @snapshot = Kaui::KillbillHelper::get_account_snapshot(@account.account_id, options_for_klient)
      rescue => e
        flash[:error] = "Error while retrieving account snapshot: #{as_string(e)}"
        redirect_to :analytics
      end
    end

    def refresh_account
      begin
        Kaui::KillbillHelper::refresh_account(params[:account_id], options_for_klient)
        flash[:notice] = "Account successfully refreshed!"
      rescue => e
        flash[:error] = "Error while refreshing account: #{as_string(e)}"
      end
      redirect_to account_snapshot_path(:account_id => params[:account_id])
    end
  end
end
