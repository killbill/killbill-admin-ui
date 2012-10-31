module Kaui
  class AnalyticsController < Kaui::EngineController
    def index
      @slugs = []
      begin
        catalog = Kaui::KillbillHelper::get_full_catalog()
        catalog['products'].each do |product|
          product['plans'].each do |plan|
            name = plan['name']
            plan['phases'].each do |phase|
              type = phase['type']
              @slugs << "#{name.downcase}-#{type.downcase}"
            end
          end
        end
        @product_type = catalog['name']
      rescue => e
        flash[:error] = "Error while retrieving catalog: #{as_string(e)}"
      end
    end

    def account_snapshot
      begin
        @account = Kaui::KillbillHelper::get_account(params[:account_id])
        @snapshot = Kaui::KillbillHelper::get_account_snapshot(params[:account_id])
      rescue => e
        flash[:error] = "Error while retrieving account snapshot: #{as_string(e)}"
        redirect_to :analytics
      end
    end

    def refresh_account
      begin
        Kaui::KillbillHelper::refresh_account(params[:account_id])
        flash[:notice] = "Account successfully refreshed!"
      rescue => e
        flash[:error] = "Error while refreshing account: #{as_string(e)}"
      end
      redirect_to :account_snapshot, :account_id => params[:account_id]
    end

    def accounts_over_time
      begin
        @accounts = Analytics.accounts_over_time
      rescue => e
        flash[:error] = "Error while retrieving data: #{as_string(e)}"
        @accounts = Kaui::TimeSeriesData.empty
      end
    end

    def subscriptions_over_time
      @product_type = params[:product_type]
      @slug = params[:slug]
      @subscriptions = Analytics.subscriptions_over_time(@product_type, @slug)
    end
  end
end
