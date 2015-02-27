module Kaui
  class AdminTenantsController < Kaui::EngineController

    skip_before_filter :check_for_redirect_to_tenant_screen

    def index
      # Display the configured tenants in KAUI (which could be different than the existing tenants known by Kill Bill)
      @tenants = Kaui::Tenant.all
      render
    end

    def new
      @tenant = Kaui::Tenant.new
    end

    def create
      param_tenant = params[:tenant]
      old_tenant = Kaui::Tenant.find_by_name(param_tenant[:name])
      if old_tenant
        flash[:error] = "Tenant with name #{param_tenant[:name]} already exists!"
        redirect_to admin_tenants_path and return
      end

      begin

        options = tenant_options_for_client
        new_tenant = nil

        if params[:create_tenant]
          # Create the tenant in Kill Bill
          new_tenant = Kaui::AdminTenant.new
          new_tenant.external_key = param_tenant[:name]
          new_tenant.api_key = param_tenant[:api_key]
          new_tenant.api_secret = param_tenant[:api_secret]
          new_tenant = new_tenant.create(options[:username], nil, comment, options)
        else
          options[:api_key] = param_tenant[:api_key]
          options[:api_secret] = param_tenant[:api_secret]
          new_tenant = Kaui::AdminTenant.find_by_api_key(param_tenant[:api_key], options)
        end

        # Transform object to Kaui model
        tenant_model = Kaui::Tenant.new
        tenant_model.name = new_tenant.external_key
        tenant_model.kb_tenant_id = new_tenant.tenant_id
        tenant_model.api_key = new_tenant.api_key
        tenant_model.api_secret = param_tenant[:api_secret]

        # Save in KAUI tables
        tenant_model.save!
      rescue => e
        flash[:error] = "Failed to create the tenant : #{as_string(e)}"
        redirect_to admin_tenants_path and return
      end

      redirect_to admin_tenant_path(tenant_model[:id]), :notice => 'Tenant was successfully configured'
    end

    def show
      @tenant = Kaui::Tenant.find(params[:id])
      render
    end

    def upload_catalog

      current_tenant = Kaui::Tenant.find_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      uploaded_catalog = params[:catalog]
      catalog_xml = uploaded_catalog.read

      Kaui::AdminTenant.upload_catalog(catalog_xml, options[:username], nil, comment, options)

      redirect_to admin_tenants_path, :notice => 'Catalog was successfully uploaded'
    end


    def remove_allowed_user

      current_tenant = Kaui::Tenant.find_by_id(params[:id])
      au = Kaui::AllowedUser.find(params[:allowed_user][:id])
      # remove the association
      au.kaui_tenants.delete current_tenant
      render :json => '{}', :status => 200
    end

    private

    def tenant_options_for_client
      user = current_user
      {
          :username => user.kb_username,
          :password => user.password,
          :session_id => user.kb_session_id
      }
    end

    def comment
      'Multi-tenant Administrative operation'
    end
  end
end
