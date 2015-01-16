class Kaui::EngineController < ApplicationController
  before_filter :authenticate_user!, :verify_tenant_info

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


  def current_ability
    # Redefined here to namespace Ability in the correct module
    @current_ability ||= Kaui::Ability.new(current_user)
  end

  def verify_tenant_info
    #  If we are trying to configure the tenant either by showing the view or selecting the tenant, there is nothing to verify
    return if Kaui.tenant_home_path.call == request.fullpath || Kaui.select_tenant.call == request.fullpath

    user = current_user
    kb_tenant_id = session[:kb_tenant_id]
    if kb_tenant_id.nil?
      redirect_to Kaui.tenant_home_path.call and return
    end

    au = Kaui::AllowedUser.find_by_kb_username(user.kb_username)
    tenant = au.kaui_tenants.select { |t| t.kb_tenant_id == kb_tenant_id }.first
    if tenant.nil?
      session[:kb_tenant_id] = nil
      redirect_to Kaui.tenant_home_path.call and return
    end
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

  private

  def current_tenant_user
    user = current_user
    kb_tenant_id = session[:kb_tenant_id]
    user_tenant = Kaui::Tenant.find_by_kb_tenant_id(kb_tenant_id) if kb_tenant_id
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

end
