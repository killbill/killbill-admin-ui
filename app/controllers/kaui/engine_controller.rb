class Kaui::EngineController < ApplicationController
  before_filter :authenticate_user!

  layout :get_layout

  # Common options for the Kill Bill client
  def options_for_klient(options = {})
    user_tenant_options = current_tenant_user
    user_tenant_options.merge(options)
    user_tenant_options
  end

  # Used for auditing purposes
  def current_user
    super
  end

  def current_tenant_user
    user = current_user
    user_tenant = user.kaui_tenant
    result = {
        :username => user.kb_username,
        :password => user.password,
        :session_id => user.kb_session_id,
    }
    if user_tenant
      result[:api_key] = user_tenant.api_key
      result[:api_secret] = user_tenant.api_secret
    end
    result
  end

  def current_ability
    # Redefined here to namespace Ability in the correct module
    @current_ability ||= Kaui::Ability.new(current_user)
  end

  protected

  def as_string(e)
    if e.is_a?(KillBillClient::API::ResponseError)
      "Error #{e.response.code}: #{as_string_from_response(e.response.body)}"
    else
      e.message
    end
  end

  def as_string_from_response(response)
    error_message = response
    begin
      # BillingExceptionJson?
      error_message = JSON.parse response
    rescue => e
    end

    if error_message.respond_to? :[] and error_message['message'].present?
      # Likely BillingExceptionJson
      error_message = error_message['message']
    end
    # Limit the error size to avoid ActionDispatch::Cookies::CookieOverflow
    error_message[0..1000]
  end

  def get_layout
    layout ||= Kaui.config[:layout]
  end
end
