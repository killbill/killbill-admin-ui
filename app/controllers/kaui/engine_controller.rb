class Kaui::EngineController < ApplicationController

  include Kaui::EngineControllerUtil

  before_action :authenticate_user!, :check_for_redirect_to_tenant_screen, :populate_account_details

  layout :get_layout

  # Common options for the Kill Bill client
  def options_for_klient(options = {})
    user_tenant_options = Kaui.current_tenant_user_options(current_user, session)
    user_tenant_options.merge(options)
    # Pass the X-Request-Id seen by Rails to Kill Bill
    # Note that this means that subsequent requests issued by a single action will share the same X-Request-Id in Kill Bill
    user_tenant_options[:request_id] ||= request.request_id
    user_tenant_options
  end

  # Used for auditing purposes
  def current_user
    super
  end

  # Called lazily by the can? helper
  def current_ability
    # Redefined here to namespace Ability in the correct module
    @current_ability ||= Kaui::Ability.new(current_user)
  end

  def check_for_redirect_to_tenant_screen
    unless Kaui.user_assigned_valid_tenant?(current_user, session)
      session[:kb_tenant_id] = nil
      redirect_to Kaui.tenant_home_path.call
    end
  end

  def populate_account_details
    @account ||= params[:account_id].present? ? Kaui::Account.find_by_id(params[:account_id], false, false, options_for_klient) : Kaui::Account.new
  end

  def retrieve_tenants_for_current_user
    if current_user.root?
      Kaui::Tenant.all.map(&:kb_tenant_id)
    else
      Kaui::AllowedUser.preload(:kaui_tenants).find_by_kb_username(current_user.kb_username).kaui_tenants.map(&:kb_tenant_id)
    end
  end

  def retrieve_allowed_users_for_current_user
    tenants_for_current_user = retrieve_tenants_for_current_user

    Kaui::AllowedUser.preload(:kaui_tenants).all.select do |user|
      tenants_for_user = user.kaui_tenants.map(&:kb_tenant_id)
      if tenants_for_user.empty?
        current_user.root?
      else
        (tenants_for_user - tenants_for_current_user).empty?
      end
    end
  end

  # Note! Order matters, StandardError needs to be first
  rescue_from(StandardError) do |error|
    flash[:error] = "Error: #{as_string(error)}"
    try_to_redirect_to_account_path = !params[:controller].ends_with?('accounts')
    perform_redirect_after_error try_to_redirect_to_account_path
  end

  rescue_from(ActionController::ParameterMissing) do |parameter_missing_exception|
    log_rescue_error parameter_missing_exception
    flash[:error] = "Required parameter missing: #{parameter_missing_exception.param}"
    perform_redirect_after_error
  end

  rescue_from(KillBillClient::API::ResponseError) do |killbill_exception|
    flash[:error] = "Error while communicating with the Kill Bill server: #{as_string(killbill_exception)}"
    try_to_redirect_to_account_path = !killbill_exception.is_a?(KillBillClient::API::Unauthorized) && !(killbill_exception.is_a?(KillBillClient::API::NotFound) && params[:controller].ends_with?('accounts'))
    perform_redirect_after_error try_to_redirect_to_account_path
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

  def perform_redirect_after_error(try_to_redirect_to_account_path = true)
    account_id = nested_hash_value(params.permit!.to_h, :account_id)
    if try_to_redirect_to_account_path && account_id.present?
      redirect_to kaui_engine.account_path(account_id)
    else
      redirect_to kaui_engine.home_path
    end
  end
end
