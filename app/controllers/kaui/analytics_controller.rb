module Kaui
  class AnalyticsController < ApplicationController
    def index
      @slugs = []
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
    end

    def accounts_over_time
      @accounts = Analytics.accounts_over_time
    end

    def subscriptions_over_time
      @product_type = params[:product_type]
      @slug = params[:slug]
      @subscriptions = Analytics.subscriptions_over_time(@product_type, @slug)
    end
  end
end