# frozen_string_literal: true

module Kaui
  module ErrorHandler
    extend ActiveSupport::Concern
    include Kaui::EngineControllerUtil

    included do
      rescue_from(StandardError) do |error|
        flash[:error] = "Error: #{as_string(error)}"
        try_to_redirect_to_account_path = !params[:controller].ends_with?('accounts')
        perform_redirect_after_error(redirect: try_to_redirect_to_account_path)
      end

      rescue_from(ActionController::ParameterMissing) do |parameter_missing_exception|
        log_rescue_error parameter_missing_exception
        flash[:error] = "Required parameter missing: #{parameter_missing_exception.param}"
        perform_redirect_after_error
      end

      rescue_from(KillBillClient::API::ResponseError) do |killbill_exception|
        flash[:error] = "Error while communicating with the Kill Bill server: #{as_string(killbill_exception)}"
        try_to_redirect_to_account_path = !killbill_exception.is_a?(KillBillClient::API::Unauthorized) && !(killbill_exception.is_a?(KillBillClient::API::NotFound) && params[:controller].ends_with?('accounts'))
        perform_redirect_after_error(redirect: try_to_redirect_to_account_path)
      end
    end

    def perform_redirect_after_error(redirect: true)
      account_id = nested_hash_value(params.permit!.to_h, :account_id)
      if redirect && account_id.present?
        redirect_to kaui_engine.account_path(account_id)
      else
        redirect_to kaui_engine.home_path
      end
    end
  end
end
