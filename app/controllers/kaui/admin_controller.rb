# frozen_string_literal: true

module Kaui
  class AdminController < Kaui::EngineController
    skip_before_action :check_for_redirect_to_tenant_screen

    def index
      begin
        @clock = Kaui::Admin.get_clock(nil, options_for_klient)
      rescue KillBillClient::API::NotFound
        flash[:error] = 'Failed to get current KB clock: Kill Bill server must be started with system property org.killbill.server.test.mode=true'
        redirect_to admin_tenants_path and return
      end

      params.permit!

      respond_to do |format|
        format.html
        format.js
      end
    end

    def set_clock
      if params[:commit] == 'Submit'
        date = Date.parse(params[:new_date]).strftime('%Y-%m-%d')
        msg = I18n.translate('flashes.notices.clock_updated_successfully', new_date: date)
      else
        date = nil
        msg = I18n.translate('flashes.notices.clock_reset_successfully')
      end
      begin
        Kaui::Admin.set_clock(date, nil, options_for_klient)
      rescue KillBillClient::API::NotFound
        flash[:error] = 'Failed to set current KB clock: Kill Bill server must be started with system property org.killbill.server.test.mode=true'
        redirect_to admin_tenants_path and return
      end

      redirect_to admin_path, notice: msg
    end
  end
end
