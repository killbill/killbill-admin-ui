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
        current_datetime = DateTime.parse(Kaui::Admin.get_clock(nil, options_for_klient)['currentUtcTime'])
        new_local_date = Date.parse(params[:new_date])
        new_datetime = DateTime.new(new_local_date.year, new_local_date.month, new_local_date.day, current_datetime.hour, current_datetime.min, current_datetime.sec, 'Z').to_s
        msg = "Clock was successfully updated to #{new_datetime}"
      else
        new_datetime = nil
        msg = 'Clock was successfully reset'
      end
      begin
        Kaui::Admin.set_clock(new_datetime, nil, options_for_klient)
      rescue KillBillClient::API::NotFound
        flash[:error] = 'Failed to set current KB clock: Kill Bill server must be started with system property org.killbill.server.test.mode=true'
        redirect_to admin_tenants_path and return
      end

      redirect_to admin_path, notice: msg
    end
  end
end
