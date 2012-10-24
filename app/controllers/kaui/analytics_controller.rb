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
