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
        # STEPH_TENANT what should we do? Why flash does not work?
        flash.now[:error] = "Error while retrieving tenants #{as_string(e)}"
        @tenants = []
      end

    end

    def select_tenant
      @tenant_name = params[:tenant_name]
      # STEPH_TENANT could we pass the tenant_id as a hidden field instead ?
      selected_tenant =  Kaui::Tenant.find_by_name(@tenant_name)
      select_tenant_for_tenant_id(selected_tenant.kb_tenant_id)
    end

    private

    def select_tenant_for_tenant_id(kb_tenant_id)
      begin
        user = current_user
        user.kb_tenant_id = kb_tenant_id
        user.save
        redirect_to Kaui.home_path.call
      rescue => e
        flash.now[:error] = "Error selecting the tenants #{@tenant_name if @tenant_name} #{as_string(e) if e}"
        # STEPH_TENANT flash does not seem to work...
        redirect_to :action => :index and return
      end
    end

  end
end
