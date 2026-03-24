# frozen_string_literal: true

module Kaui
  module ErrorHandler
    extend ActiveSupport::Concern
    include Kaui::EngineControllerUtil

    included do
      rescue_from(StandardError) do |error|
        error_message = "Error: #{as_string(error)}"
        try_to_redirect_to_account_path = !params[:controller].ends_with?('accounts')
        perform_redirect_after_error(redirect: try_to_redirect_to_account_path, error:, error_message:)
      end

      rescue_from(ActionController::ParameterMissing) do |parameter_missing_exception|
        log_rescue_error parameter_missing_exception
        error_message = "Required parameter missing: #{parameter_missing_exception.param}"
        perform_redirect_after_error(error: parameter_missing_exception, error_message:)
      end

      rescue_from(KillBillClient::API::ResponseError) do |killbill_exception|
        error_message = "Error while communicating with the Kill Bill server: #{as_string(killbill_exception)}"
        try_to_redirect_to_account_path = !killbill_exception.is_a?(KillBillClient::API::Unauthorized) && !(killbill_exception.is_a?(KillBillClient::API::NotFound) && params[:controller].ends_with?('accounts'))
        perform_redirect_after_error(redirect: try_to_redirect_to_account_path, error: killbill_exception, error_message:)
      end
    end

    def perform_redirect_after_error(error:, error_message:, redirect: true)
      account_id = nested_hash_value(params.permit!.to_h, :account_id)
      home_path = kaui_engine.home_path
      redirect_path = if redirect && account_id.present?
                        kaui_engine.account_path(account_id)
                      else
                        home_path
                      end

      redirect_path_without_query = redirect_path.to_s.split('?').first
      already_on_redirect_target = request.path == redirect_path_without_query
      already_on_home = params[:controller].to_s.ends_with?('home') && action_name == 'index'

      raise error if already_on_redirect_target || (redirect_path == home_path && already_on_home)

      flash[:error] = error_message
      redirect_to redirect_path
    end
  end
end
