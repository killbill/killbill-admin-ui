# frozen_string_literal: true

module Kaui
  class AdminTenantsController < Kaui::EngineController
    skip_before_action :check_for_redirect_to_tenant_screen

    def index
      # Display the configured tenants in KAUI (which could be different than the existing tenants known by Kill Bill)
      tenants_for_current_user = retrieve_tenants_for_current_user
      @tenants = Kaui::Tenant.all.select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }
    end

    def new
      @tenant = Kaui::Tenant.new
    end

    def create
      param_tenant = params[:tenant]

      old_tenant = Kaui::Tenant.find_by_name(param_tenant[:name]) || Kaui::Tenant.find_by_api_key(param_tenant[:api_key])
      if old_tenant
        old_tenant.kaui_allowed_users << Kaui::AllowedUser.where(kb_username: current_user.kb_username).first_or_create
        redirect_to admin_tenant_path(old_tenant[:id]), notice: 'Tenant was successfully configured' and return
      end

      begin
        options = tenant_options_for_client
        new_tenant = nil

        begin
          options[:api_key] = param_tenant[:api_key]
          options[:api_secret] = param_tenant[:api_secret]
          new_tenant = Kaui::AdminTenant.find_by_api_key(param_tenant[:api_key], options)
        rescue KillBillClient::API::Unauthorized, KillBillClient::API::NotFound
          # Create the tenant in Kill Bill
          new_tenant = Kaui::AdminTenant.new
          new_tenant.external_key = param_tenant[:name]
          new_tenant.api_key = param_tenant[:api_key]
          new_tenant.api_secret = param_tenant[:api_secret]
          new_tenant = new_tenant.create(false, options[:username], nil, comment, options)
        end

        # Transform object to Kaui model
        tenant_model = Kaui::Tenant.new
        tenant_model.name = param_tenant[:name]
        tenant_model.api_key = param_tenant[:api_key]
        tenant_model.api_secret = param_tenant[:api_secret]
        tenant_model.kb_tenant_id = new_tenant.tenant_id

        # Save in KAUI tables
        tenant_model.save!
        # Make sure at least the current user can access the tenant
        tenant_model.kaui_allowed_users << Kaui::AllowedUser.where(kb_username: current_user.kb_username).first_or_create
      rescue KillBillClient::API::Conflict => _e
        # tenant api_key was found but has a wrong api_secret
        flash[:error] = "Submitted credentials for #{param_tenant[:api_key]} did not match the expected credentials."
        redirect_to admin_tenants_path and return
      rescue StandardError => e
        flash[:error] = "Failed to create the tenant: #{as_string(e)}"
        redirect_to admin_tenants_path and return
      end

      # Select the tenant, see TenantsController
      session[:kb_tenant_id] = tenant_model.kb_tenant_id
      session[:kb_tenant_name] = tenant_model.name
      session[:tenant_id] = tenant_model.id

      redirect_to admin_tenant_path(tenant_model[:id]), notice: 'Tenant was successfully configured'
    end

    def show
      @tenant = safely_find_tenant_by_id(params[:id])
      @allowed_users = @tenant.kaui_allowed_users & retrieve_allowed_users_for_current_user

      configure_tenant_if_nil(@tenant)

      options = tenant_options_for_client
      options[:api_key] = @tenant.api_key
      options[:api_secret] = @tenant.api_secret

      fetch_catalog_versions = promise do
        Kaui::Catalog.get_tenant_catalog_versions(nil, options)
      rescue StandardError
        @catalog_versions = []
      end
      fetch_overdue = promise do
        Kaui::Overdue.get_overdue_json(options)
      rescue StandardError
        @overdue = nil
      end
      fetch_overdue_xml = promise do
        Kaui::Overdue.get_tenant_overdue_config(options)
      rescue StandardError
        @overdue_xml = nil
      end

      fetch_tenant_plugin_config = promise { Kaui::AdminTenant.get_tenant_plugin_config(options) }

      @catalog_versions = []
      wait(fetch_catalog_versions).each_with_index do |effective_date, idx|
        @catalog_versions << { version: idx,
                               version_date: effective_date }
      end

      @latest_version = begin
        @catalog_versions[@catalog_versions.length - 1][:version_date]
      rescue StandardError
        nil
      end

      @overdue = wait(fetch_overdue)
      @overdue_xml = wait(fetch_overdue_xml)
      @tenant_plugin_config = begin
        wait(fetch_tenant_plugin_config)
      rescue StandardError
        ''
      end

      # When reloading page from the view, it sends the last tab that was active
      @active_tab = params[:active_tab] || 'CatalogShow'
    end

    def upload_catalog
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      uploaded_catalog = params.require(:catalog)
      catalog_xml = uploaded_catalog.read

      validate_response = Kaui::Catalog.validate_catalog(catalog_xml, options[:username], nil, comment, options)
      catalog_validation_errors = begin
        JSON.parse(validate_response.response.body)['catalogValidationErrors']
      rescue StandardError
        nil
      end
      if catalog_validation_errors.blank?
        Kaui::AdminTenant.upload_catalog(catalog_xml, options[:username], nil, comment, options)
        redirect_to admin_tenant_path(current_tenant.id), notice: I18n.translate('flashes.notices.catalog_uploaded_successfully')
      else
        errors = ''
        catalog_validation_errors.each do |validation_error|
          errors += validation_error['errorDescription']
        end
        flash[:error] = errors
        redirect_to admin_tenant_new_catalog_path(id: current_tenant.id)
      end
    end

    def new_catalog
      options = tenant_options_for_client
      fetch_state_for_new_catalog_screen(options)
      @simple_plan = Kaui::SimplePlan.new({
                                            product_category: 'BASE',
                                            amount: 0,
                                            trial_length: 0,
                                            currency: 'USD',
                                            billing_period: 'MONTHLY'
                                          })
    end

    def delete_catalog
      tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = tenant.api_key
      options[:api_secret] = tenant.api_secret

      begin
        Kaui::Catalog.delete_catalog(options[:username], 'KAUI wrong catalog', comment, options)
      rescue NoMethodError => _e
        flash[:error] = 'Failed to delete catalog: only available in KB 0.19+ versions'
        redirect_to admin_tenants_path and return
      end

      redirect_to admin_tenant_path(tenant.id), notice: 'Catalog was successfully deleted'
    end

    def new_plan_currency
      @tenant = safely_find_tenant_by_id(params[:id])

      is_plan_id_found = false
      plan_id = params[:plan_id]

      options = tenant_options_for_client
      options[:api_key] = @tenant.api_key
      options[:api_secret] = @tenant.api_secret

      catalog = Kaui::Catalog.get_catalog_json(true, nil, nil, options)

      # seek if plan id exists
      catalog.products.each do |product|
        product.plans.each { |plan| is_plan_id_found |= plan.name == plan_id }
        break if is_plan_id_found
      end

      unless is_plan_id_found
        flash[:error] = "Plan id #{plan_id} was not found."
        redirect_to admin_tenant_path(@tenant[:id])
      end

      @simple_plan = Kaui::SimplePlan.new
      @simple_plan.plan_id = params[:plan_id]
    end

    def create_simple_plan
      options = tenant_options_for_client
      fetch_state_for_new_catalog_screen(options)

      simple_plan = params.require(:simple_plan).delete_if { |_e, value| value.blank? }
      # Fix issue in Rails where first entry in the multi-select array is an empty string
      simple_plan['available_base_products']&.reject!(&:blank?)

      @simple_plan = Kaui::SimplePlan.new(simple_plan)

      valid = true
      # Validate new simple plan
      # https://github.com/killbill/killbill-admin-ui/issues/247
      if @available_base_products.include?(@simple_plan.plan_id)
        flash.now[:error] = "Error while creating plan: invalid plan name (#{@simple_plan.plan_id} is a BASE product already)"
        valid = false
      elsif @available_ao_products.include?(@simple_plan.plan_id)
        flash.now[:error] = "Error while creating plan: invalid plan name (#{@simple_plan.plan_id} is an ADD_ON product already)"
        valid = false
      elsif @available_standalone_products.include?(@simple_plan.plan_id)
        flash.now[:error] = "Error while creating plan: invalid plan name (#{@simple_plan.plan_id} is a STANDALONE product already)"
        valid = false
      elsif @all_plans.include?(@simple_plan.product_name)
        flash.now[:error] = "Error while creating plan: invalid product name (#{@simple_plan.product_name} is a plan name already)"
        valid = false
      elsif @all_plans.include?(@simple_plan.plan_id)
        flash.now[:error] = "Error while creating plan: plan #{@simple_plan.plan_id} already exists"
        valid = false
      elsif @available_base_products.include?(@simple_plan.product_name) && @simple_plan.product_category != 'BASE'
        flash.now[:error] = "Error while creating plan: product #{@simple_plan.product_name} is a BASE product"
        valid = false
      elsif @available_ao_products.include?(@simple_plan.product_name) && @simple_plan.product_category != 'ADD_ON'
        flash.now[:error] = "Error while creating plan: product #{@simple_plan.product_name} is an ADD_ON product"
        valid = false
      elsif @available_standalone_products.include?(@simple_plan.product_name) && @simple_plan.product_category != 'STANDALONE'
        flash.now[:error] = "Error while creating plan: product #{@simple_plan.product_name} is a STANDALONE product"
        valid = false
      end

      if valid
        begin
          Kaui::Catalog.add_tenant_catalog_simple_plan(@simple_plan, options[:username], nil, comment, options)
          redirect_to admin_tenant_path(@tenant.id), notice: 'Catalog plan was successfully added'
        rescue StandardError => e
          flash.now[:error] = "Error while creating plan: #{as_string(e)}"
          render action: :new_catalog
        end
      else
        render action: :new_catalog
      end
    end

    def new_overdue_config
      @tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = @tenant.api_key
      options[:api_secret] = @tenant.api_secret
      @overdue = Kaui::Overdue.get_overdue_json(options)
    end

    def modify_overdue_config
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      view_form_model = params.require(:kill_bill_client_model_overdue).delete_if { |_e, value| value.blank? }
      view_form_model['states'] = view_form_model['states'].values unless view_form_model['states'].blank?

      overdue = Kaui::Overdue.from_overdue_form_model(view_form_model)
      Kaui::Overdue.upload_tenant_overdue_config_json(overdue.to_json, options[:username], nil, comment, options)
      redirect_to admin_tenant_path(current_tenant.id, active_tab: 'OverdueShow'), notice: I18n.translate('flashes.notices.overdue_added_successfully')
    end

    def upload_overdue_config
      uploaded_overdue_config = params.require(:overdue)
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      overdue_config_xml = uploaded_overdue_config.read

      begin
        Nokogiri::XML(overdue_config_xml, &:strict)
      rescue Nokogiri::XML::SyntaxError => e
        flash[:error] = I18n.translate('errors.messages.invalid_xml', error: e)
        redirect_to admin_tenant_path(current_tenant.id) and return
      end

      Kaui::AdminTenant.upload_overdue_config(overdue_config_xml, options[:username], nil, comment, options)

      redirect_to admin_tenant_path(current_tenant.id, active_tab: 'OverdueShow'), notice: I18n.translate('flashes.notices.overdue_uploaded_successfully')
    end

    def upload_invoice_template
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      is_manual_pay = params[:manual_pay]
      uploaded_invoice_template = params.require(:invoice_template)
      invoice_template = uploaded_invoice_template.read

      Kaui::AdminTenant.upload_invoice_template(invoice_template, is_manual_pay, true, options[:username], nil, comment, options)

      redirect_to admin_tenant_path(current_tenant.id), notice: I18n.translate('flashes.notices.invoice_template_uploaded_successfully')
    end

    def upload_invoice_translation
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      locale = params[:translation_locale]
      uploaded_invoice_translation = params.require(:invoice_translation)
      invoice_translation = uploaded_invoice_translation.read

      Kaui::AdminTenant.upload_invoice_translation(invoice_translation, locale, true, options[:username], nil, comment, options)

      redirect_to admin_tenant_path(current_tenant.id), notice: I18n.translate('flashes.notices.invoice_translation_uploaded_successfully')
    end

    def upload_catalog_translation
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      locale = params[:translation_locale]
      uploaded_catalog_translation = params.require(:catalog_translation)
      catalog_translation = uploaded_catalog_translation.read

      Kaui::AdminTenant.upload_catalog_translation(catalog_translation, locale, true, options[:username], nil, comment, options)

      redirect_to admin_tenant_path(current_tenant.id), notice: I18n.translate('flashes.notices.catalog_translation_uploaded_successfully')
    end

    def upload_plugin_config
      current_tenant = safely_find_tenant_by_id(params[:id])

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      plugin_name = params[:plugin_name]
      plugin_properties = params[:plugin_properties]
      plugin_type = params[:plugin_type]
      plugin_key = params[:plugin_key]

      if plugin_properties.blank?
        flash[:error] = 'Plugin properties cannot be blank'
      elsif plugin_name.blank?
        flash[:error] = 'Plugin name cannot be blank'
      else
        plugin_config = Kaui::AdminTenant.format_plugin_config(plugin_key, plugin_type, plugin_properties)

        Kaui::AdminTenant.upload_tenant_plugin_config(plugin_name, plugin_config, options[:username], nil, comment, options)
        flash[:notice] = 'Config for plugin was successfully uploaded'
      end

      redirect_to admin_tenant_path(current_tenant.id, active_tab: 'PluginConfig')
    end

    def remove_allowed_user
      current_tenant = safely_find_tenant_by_id(params[:id])
      au = Kaui::AllowedUser.find(params.require(:allowed_user).require(:id))

      unless current_user.root?
        render json: { alert: 'Only the root user can remove users from tenants' }.to_json, status: 401
        return
      end

      # remove the association
      au.kaui_tenants.delete current_tenant
      render json: '{}', status: 200
    end

    def add_allowed_user
      current_tenant = safely_find_tenant_by_id(params[:tenant_id])
      allowed_user = Kaui::AllowedUser.find_by_kb_username(params.require(:allowed_user).require(:kb_username))

      unless current_user.root?
        flash[:error] = 'Only the root user can add users from tenants'
        redirect_to admin_tenant_path(current_tenant.id)
        return
      end

      if allowed_user.nil?
        flash[:error] = "User #{params.require(:allowed_user).require(:kb_username)} does not exist!"
        redirect_to admin_tenant_path(current_tenant.id)
        return
      end

      tenants_ids = allowed_user.kaui_tenants.map(&:id) || []
      tenants_ids << current_tenant.id
      allowed_user.kaui_tenant_ids = tenants_ids
      redirect_to admin_tenant_path(current_tenant.id), notice: 'Allowed user was successfully added'
    end

    def allowed_users
      json_response do
        tenant = safely_find_tenant_by_id(params[:tenant_id])
        actual_allowed_users = tenant.kaui_allowed_users.map(&:id)

        retrieve_allowed_users_for_current_user.reject { |au| actual_allowed_users.include? au.id }
      end
    end

    def display_catalog_xml
      catalog_xml = fetch_catalog_xml(params[:id], params.require(:effective_date))
      render xml: catalog_xml
    end

    def download_catalog_xml
      effective_date = params.require(:effective_date)
      catalog_xml = fetch_catalog_xml(params[:id], effective_date)
      send_data catalog_xml, filename: "catalog_#{effective_date}.xml", type: :xml
    end

    def display_overdue_xml
      render xml: params.require(:xml)
    end

    def catalog_by_effective_date
      json_response do
        current_tenant = safely_find_tenant_by_id(params[:id])
        effective_date = params.require(:effective_date)

        options = tenant_options_for_client
        options[:api_key] = current_tenant.api_key
        options[:api_secret] = current_tenant.api_secret

        catalog = []
        result = begin
          Kaui::Catalog.get_catalog_json(false, effective_date, nil, options)
        rescue StandardError
          catalog = []
        end

        # convert result to a full hash since dynamic attributes of a class are ignored when converting to json
        result.each do |data|
          plans = data[:plans].map do |plan|
            plan.instance_variables.each_with_object({}) { |var, hash_plan| hash_plan[var.to_s.delete('@')] = plan.instance_variable_get(var) }
          end

          catalog << { version_date: data[:version_date],
                       currencies: data[:currencies],
                       plans: }
        end

        { catalog: }
      end
    end

    def switch_tenant
      tenant = Kaui::Tenant.find_by_kb_tenant_id(params.require(:kb_tenant_id))

      # Select the tenant, see TenantsController
      session[:kb_tenant_id] = tenant.kb_tenant_id
      session[:kb_tenant_name] = tenant.name
      session[:tenant_id] = tenant.id

      redirect_to admin_tenant_path(tenant.id), notice: "Tenant was switched to #{tenant.name}"
    end

    private

    # Share code to handle render on error
    def fetch_state_for_new_catalog_screen(options)
      @tenant = safely_find_tenant_by_id(params[:id])

      options[:api_key] = @tenant.api_key
      options[:api_secret] = @tenant.api_secret

      latest_catalog = Kaui::Catalog.get_catalog_json(true, nil, nil, options)
      @all_plans = latest_catalog ? (latest_catalog.products || []).map(&:plans).flatten.map(&:name) : []

      @ao_mapping = Kaui::Catalog.build_ao_mapping(latest_catalog)

      @available_base_products = if latest_catalog&.products
                                   latest_catalog.products.select { |p| p.type == 'BASE' }.map(&:name)
                                 else
                                   []
                                 end
      @available_ao_products = if latest_catalog&.products
                                 latest_catalog.products.select { |p| p.type == 'ADD_ON' }.map(&:name)
                               else
                                 []
                               end
      @available_standalone_products = if latest_catalog&.products
                                         latest_catalog.products.select { |p| p.type == 'STANDALONE' }.map(&:name)
                                       else
                                         []
                                       end
      @product_categories = %i[BASE ADD_ON STANDALONE]
      @billing_period = %i[DAILY WEEKLY BIWEEKLY THIRTY_DAYS THIRTY_ONE_DAYS MONTHLY QUARTERLY BIANNUAL ANNUAL SESQUIENNIAL BIENNIAL TRIENNIAL]
      @time_units = %i[UNLIMITED DAYS WEEKS MONTHS YEARS]
    end

    def safely_find_tenant_by_id(tenant_id)
      tenant = Kaui::Tenant.find_by_id(tenant_id)
      raise ActiveRecord::RecordNotFound, "Could not find tenant #{tenant_id}" unless retrieve_tenants_for_current_user.include?(tenant.kb_tenant_id)

      tenant
    end

    def tenant_options_for_client
      user = current_user
      {
        username: user.kb_username,
        password: user.password,
        session_id: user.kb_session_id
      }
    end

    def comment
      'Multi-tenant Administrative operation'
    end

    def configure_tenant_if_nil(tenant)
      return unless session[:kb_tenant_id].nil?

      session[:kb_tenant_id] = tenant.kb_tenant_id
      session[:kb_tenant_name] = tenant.name
      session[:tenant_id] = tenant.id
    end

    def split_camel_dash_underscore_space(data)
      # to_s to handle nil
      data.to_s.split(/(?=[A-Z])|(?=_)|(?=-)|(?= )/).reject { |member| member.gsub(/[_-]/, '').strip.empty? }.map { |member| member.gsub(/[_-]/, '').strip.downcase }
    end

    def fetch_catalog_xml(tenant_id, effective_date)
      current_tenant = safely_find_tenant_by_id(tenant_id)

      options = tenant_options_for_client
      options[:api_key] = current_tenant.api_key
      options[:api_secret] = current_tenant.api_secret

      response = begin
        Kaui::Catalog.get_catalog_xml(effective_date, options)
      rescue StandardError
        {}
      end

      catalog_xml = {}
      catalog_xml = response[0][:xml] unless response.blank?

      catalog_xml
    end
  end
end
