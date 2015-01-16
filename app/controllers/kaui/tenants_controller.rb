module Kaui
  class TenantsController < Kaui::EngineController

    def index
      begin

        # Retrieve current user and extract allowed list of tenants
        user = current_user
        allowed_user = Kaui::AllowedUser.find_by_kb_username(user.kb_username)
        @tenants = (allowed_user.kaui_tenants if allowed_user) || []

        #
        # If there is nothing we check for override with KillBillClient.api_key/KillBillClient.api_secret
        # If there is only one, we skip the tenant screen since the choice is obvious
        # If not, we allow user to chose what he wants
        #
        case @tenants.size
          when 0
            # If KillBillClient.api_key and KillBillClient.api_secret are not set, the client library will throw
            # an KillBillClient::API::Unauthorized exception which will end up in the rescue below
            tenant = KillBillClient::Model::Tenant.find_by_api_key(KillBillClient.api_key, {
                :session_id => user.kb_session_id
            })
            kb_tenant_id = tenant.tenant_id if tenant.present?
            select_tenant_for_tenant_id(kb_tenant_id)
          when 1
            # If there is only one tenant defined we skip the screen and set the tenant for the user
            select_tenant_for_tenant_id(@tenants[0].kb_tenant_id)
          else
            # Jump to default view allowing to chose which tenant to pick
            respond_to do |format|
              format.html # index.html.erb
              format.json { render :json => @tenants }
            end
        end
      rescue => e
        flash[:error] = "Error while retrieving tenants: No tenants configured for users AND KillBillClient.api_key, KillBillClient.api_secret have not been set"
        @tenants = []
        # We then display the view with NO tenants and the flash error so user understands he does not have any configured tenants available
      end

    end

    def select_tenant
      kb_tenant_id = params[:kb_tenant_id]
      select_tenant_for_tenant_id(kb_tenant_id)
    end

    private

    def select_tenant_for_tenant_id(kb_tenant_id)
      # Set kb_tenant_id in the session
      session[:kb_tenant_id] = kb_tenant_id
      redirect_to Kaui.home_path.call
    end

  end
end
