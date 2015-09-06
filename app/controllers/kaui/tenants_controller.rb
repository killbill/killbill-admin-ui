class Kaui::TenantsController < Kaui::EngineController

  skip_before_filter :check_for_redirect_to_tenant_screen

  def index
    # Retrieve current user and extract allowed list of tenants
    allowed_user = Kaui::AllowedUser.find_by_kb_username(current_user.kb_username)
    @tenants = (allowed_user && allowed_user.kaui_tenants) || []

    #
    # If there is nothing, we check for override with KillBillClient.api_key/KillBillClient.api_secret
    # If there is only one, we skip the tenant screen since the choice is obvious
    # If not, we allow user to choose what he wants
    #
    case @tenants.size
      when 0
        # If KillBillClient.api_key and KillBillClient.api_secret are not set, the client library will throw
        # an KillBillClient::API::Unauthorized exception which will end up in the rescue below
        tenant = KillBillClient::Model::Tenant.find_by_api_key(KillBillClient.api_key, :session_id => current_user.kb_session_id)
        select_tenant_for_tenant_id(tenant.tenant_id, tenant.external_key) if tenant.present?
      when 1
        # If there is only one tenant defined we skip the screen and set the tenant for the user
        select_tenant_for_tenant_id(@tenants[0].kb_tenant_id, @tenants[0].name)
      else
        # Jump to default view allowing to chose which tenant to pick
    end
  rescue
    flash.now[:error] = 'Error while retrieving tenants: No tenants configured for users AND KillBillClient.api_key, KillBillClient.api_secret have not been set'
    @tenants = []
    # We then display the view with NO tenants and the flash error so user understands he does not have any configured tenants available
  end

  def select_tenant
    tenant = Kaui::Tenant.find_by_kb_tenant_id(params.require(:kb_tenant_id))
    select_tenant_for_tenant_id(tenant.kb_tenant_id, tenant.name)
  end

  private

  def select_tenant_for_tenant_id(kb_tenant_id, kb_tenant_name_or_key)
    # Set kb_tenant_id in the session
    session[:kb_tenant_id] = kb_tenant_id
    session[:kb_tenant_name] = kb_tenant_name_or_key

    # Devise will have stored the requested url while signed-out
    redirect_to stored_location_for(:user) || Kaui.home_path.call
  end
end
