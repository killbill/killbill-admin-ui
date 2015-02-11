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
      old_tenant = Kaui::Tenant.find_by_name(param_tenant['name'])
      if old_tenant
        flash[:error] = "Tenant with name #{param_tenant['name']} already exists!"
        redirect_to admin_tenants_path and return
      end

      begin
        # Create the tenant in Kill Bill
        new_tenant = Kaui::AdminTenant.new
        new_tenant.external_key = param_tenant[:name]
        new_tenant.api_key = param_tenant[:api_key]
        new_tenant.api_secret = param_tenant[:api_secret]

        # STEPH Fix user/pwd
        options = {
            :username => 'admin',
            :password => 'password'
        }

        tenant_model = new_tenant.create('admin', nil, nil, options)

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

      # STEPH Fix user/pwd
      options = {
          :username => 'admin',
          :password => 'password',
          :api_key => current_tenant.api_key,
          :api_secret => current_tenant.api_secret
      }

      uploaded_catalog = params[:catalog]
      catalog_xml = uploaded_catalog.read


      Kaui::AdminTenant.upload_catalog(catalog_xml, 'admin', nil, nil, options)

      redirect_to admin_tenants_path, :notice => 'Catalog was successfully uploaded'
    end
  end
end
