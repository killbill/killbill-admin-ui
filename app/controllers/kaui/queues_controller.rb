# frozen_string_literal: true

module Kaui
  class QueuesController < Kaui::EngineController
    # rubocop:disable Lint/SuppressedException,Lint/EnsureReturn
    def index
      @account_id = params[:account_id]

      unless params[:max_date].blank?
        begin
          max_date_test = Time.parse(params[:max_date]).iso8601
        rescue StandardError
        ensure
          if max_date_test.nil?
            flash[:error] = I18n.translate('errors.messages.invalid_max_date')
            redirect_to account_queues_path(@account.account_id) and return
          end
        end
      end

      unless params[:min_date].blank?
        begin
          min_date_test = Time.parse(params[:min_date]).iso8601
        rescue StandardError
        ensure
          if min_date_test.nil?
            flash[:error] = I18n.translate('errors.messages.invalid_min_date')
            redirect_to account_queues_path(@account.account_id) and return
          end
        end
      end

      begin
        @now = Kaui::Admin.get_clock(nil, options_for_klient)['currentUtcTime'].to_datetime
      rescue KillBillClient::API::NotFound
        # If TestResource is not bound, then clock has not been manipulated, we can default to NOW
        @now = DateTime.now.in_time_zone('UTC')
      end

      min_date = (Time.parse(params[:min_date]).iso8601 unless params[:min_date].blank?) || '1970-01-01'
      max_date = (Time.parse(params[:max_date]).iso8601 unless params[:max_date].blank?) || Time.now.iso8601

      with_history = params[:with_history] || false
      @queues_entries = Kaui::Admin.get_queues_entries(@account_id,
                                                       options_for_klient.merge(withHistory: with_history,
                                                                                minDate: min_date, maxDate: max_date))

      params.permit!
    end
    # rubocop:enable Lint/SuppressedException,Lint/EnsureReturn
  end
end
