class Kaui::AdminTenantsController < Kaui::EngineController

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
      old_tenant.kaui_allowed_users << Kaui::AllowedUser.where(:kb_username => current_user.kb_username).first_or_create
      redirect_to admin_tenant_path(old_tenant[:id]), :notice => 'Tenant was successfully configured' and return
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
      tenant_model.kaui_allowed_users << Kaui::AllowedUser.where(:kb_username => current_user.kb_username).first_or_create
    rescue KillBillClient::API::Conflict => e
      # tenant api_key was found but has a wrong api_secret
      flash[:error] = "Submitted credentials for #{param_tenant[:api_key]} did not match the expected credentials."
      redirect_to admin_tenants_path and return
    rescue => e
      flash[:error] = "Failed to create the tenant: #{as_string(e)}"
      redirect_to admin_tenants_path and return
    end

    # Select the tenant, see TenantsController
    session[:kb_tenant_id] = tenant_model.kb_tenant_id
    session[:kb_tenant_name] = tenant_model.name
    session[:tenant_id] = tenant_model.id

    redirect_to admin_tenant_path(tenant_model[:id]), :notice => 'Tenant was successfully configured'
  end

  def show
    @tenant = safely_find_tenant_by_id(params[:id])
    @allowed_users = @tenant.kaui_allowed_users & retrieve_allowed_users_for_current_user

    set_tenant_if_nil(@tenant)

    options = tenant_options_for_client
    options[:api_key] = @tenant.api_key
    options[:api_secret] = @tenant.api_secret

    fetch_catalog_versions = promise { Kaui::Catalog::get_tenant_catalog_versions(options) rescue @catalog_versions = []}
    fetch_overdue = promise { Kaui::Overdue::get_overdue_json(options) rescue @overdue = nil }
    fetch_overdue_xml = promise { Kaui::Overdue::get_tenant_overdue_config('xml', options) rescue @overdue_xml = nil }

    plugin_repository = Kaui::AdminTenant::get_plugin_repository
    # hack:: replace paypal key with paypal_express, to set configuration and allow the ui to find the right configuration inputs
    plugin_repository = plugin_repository.inject({}) { |p, (k,v)| p[k.to_s.sub(/\Apaypal/, 'paypal_express').to_sym] = v; p }

    fetch_plugin_config = promise { Kaui::AdminTenant::get_oss_plugin_info(plugin_repository) }
    fetch_tenant_plugin_config = promise { Kaui::AdminTenant::get_tenant_plugin_config(plugin_repository, options) }

    @catalog_versions = []
    wait(fetch_catalog_versions).each_with_index do |effective_date, idx|
      @catalog_versions << {:version => idx,
                            :version_date => effective_date}
    end

    @latest_version = @catalog_versions[@catalog_versions.length - 1][:version_date] rescue nil

    @overdue = wait(fetch_overdue)
    @overdue_xml = wait(fetch_overdue_xml)
    @plugin_config = wait(fetch_plugin_config) rescue ''
    @tenant_plugin_config = wait(fetch_tenant_plugin_config) rescue ''

    # When reloading page from the view, it sends the last tab that was active
    @active_tab = params[:active_tab] || 'CatalogShow'
  end

  def upload_catalog
    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    uploaded_catalog = params[:catalog]
    catalog_xml = uploaded_catalog.read

    Kaui::AdminTenant.upload_catalog(catalog_xml, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Catalog was successfully uploaded'
  end

  def new_catalog


    @tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = @tenant.api_key
    options[:api_secret] = @tenant.api_secret

    latest_catalog = Kaui::Catalog::get_catalog_json(true, nil, options)

    @ao_mapping = Kaui::Catalog::build_ao_mapping(latest_catalog)

    @available_base_products = latest_catalog && latest_catalog.products ?
        latest_catalog.products.select { |p| p.type == 'BASE' }.map { |p| p.name } : []
    @available_ao_products = latest_catalog && latest_catalog.products ?
        latest_catalog.products.select { |p| p.type == 'ADD_ON' }.map { |p| p.name } : []
    @available_standalone_products = latest_catalog && latest_catalog.products ?
        latest_catalog.products.select { |p| p.type == 'STANDALONE' }.map { |p| p.name } : []
    @product_categories = [:BASE, :ADD_ON, :STANDALONE]
    @billing_period = [:DAILY, :WEEKLY, :BIWEEKLY, :THIRTY_DAYS, :MONTHLY, :QUARTERLY, :BIANNUAL, :ANNUAL, :BIENNIAL]
    @time_units = [:UNLIMITED, :DAYS, :WEEKS, :MONTHS, :YEARS]

    @simple_plan = Kaui::SimplePlan.new
  end

  def delete_catalog

    tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = tenant.api_key
    options[:api_secret] = tenant.api_secret

    begin
      Kaui::Catalog.delete_catalog(options[:username], 'KAUI wrong catalog', comment, options)
    rescue  NoMethodError => _
      flash[:error] = 'Failed to delete catalog: only available in KB 0.19+ versions'
      redirect_to admin_tenants_path and return
    end

    redirect_to admin_tenant_path(tenant.id), :notice => 'Catalog was successfully deleted'
  end

  def new_plan_currency
    @tenant = safely_find_tenant_by_id(params[:id])

    is_plan_id_found = false
    plan_id = params[:plan_id]

    options = tenant_options_for_client
    options[:api_key] = @tenant.api_key
    options[:api_secret] = @tenant.api_secret

    catalog = Kaui::Catalog::get_catalog_json(true, nil, options)

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

    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    simple_plan = params.require(:simple_plan).delete_if { |e, value| value.blank? }
    # Fix issue in Rails where first entry in the multi-select array is an empty string
    simple_plan["available_base_products"].reject!(&:blank?) if simple_plan["available_base_products"]

    simple_plan = KillBillClient::Model::SimplePlanAttributes.new(simple_plan)

    Kaui::Catalog.add_tenant_catalog_simple_plan(simple_plan, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Catalog plan was successfully added'
  end

  def new_overdue_config
    @tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = @tenant.api_key
    options[:api_secret] = @tenant.api_secret
    @overdue = Kaui::Overdue::get_overdue_json(options)
  end

  def modify_overdue_config

    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    view_form_model = params.require(:kill_bill_client_model_overdue).delete_if { |e, value| value.blank? }
    view_form_model['states'] = view_form_model['states'].values unless view_form_model['states'].blank?

    overdue = Kaui::Overdue::from_overdue_form_model(view_form_model)
    Kaui::Overdue::upload_tenant_overdue_config_json(overdue.to_json,options[:username], nil, comment, options)
    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Overdue config was successfully added '
  end


  def upload_overdue_config
    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    uploaded_overdue_config = params[:overdue]
    overdue_config_xml = uploaded_overdue_config.read

    Kaui::AdminTenant.upload_overdue_config(overdue_config_xml, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Overdue config was successfully uploaded'
  end


  def upload_invoice_template
    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    is_manual_pay = params[:manual_pay]
    uploaded_invoice_template = params[:invoice_template]
    invoice_template = uploaded_invoice_template.read

    Kaui::AdminTenant.upload_invoice_template(invoice_template, is_manual_pay, true, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Invoice template was successfully uploaded'
  end

  def upload_invoice_translation
    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    locale = params[:translation_locale]
    uploaded_invoice_translation = params[:invoice_translation]
    invoice_translation = uploaded_invoice_translation.read

    Kaui::AdminTenant.upload_invoice_translation(invoice_translation, locale, true, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Invoice translation was successfully uploaded'
  end

  def upload_catalog_translation
    current_tenant = safely_find_tenant_by_id(params[:id])

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    locale = params[:translation_locale]
    uploaded_catalog_translation = params[:catalog_translation]
    catalog_translation = uploaded_catalog_translation.read

    Kaui::AdminTenant.upload_catalog_translation(catalog_translation, locale, true, options[:username], nil, comment, options)

    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Catalog translation was successfully uploaded'
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
    else
      plugin_config = Kaui::AdminTenant.format_plugin_config(plugin_key, plugin_type, plugin_properties)

      Kaui::AdminTenant.upload_tenant_plugin_config(plugin_name, plugin_config, options[:username], nil, comment, options)
      flash[:notice] = 'Config for plugin was successfully uploaded'
    end

    redirect_to admin_tenant_path(current_tenant.id)
  end

  def remove_allowed_user
    current_tenant = safely_find_tenant_by_id(params[:id])
    au = Kaui::AllowedUser.find(params.require(:allowed_user).require(:id))

    if !current_user.root?
      render :json => {:alert => 'Only the root user can remove users from tenants'}.to_json, :status => 401
      return
    end

    # remove the association
    au.kaui_tenants.delete current_tenant
    render :json => '{}', :status => 200
  end

  def add_allowed_user
    current_tenant = safely_find_tenant_by_id(params[:tenant_id])
    allowed_user = Kaui::AllowedUser.find_by_kb_username(params.require(:allowed_user).require(:kb_username))

    if !current_user.root?
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
    redirect_to admin_tenant_path(current_tenant.id), :notice => 'Allowed user was successfully added'
  end

  def allowed_users
    json_response do
      tenant = safely_find_tenant_by_id(params[:tenant_id])
      actual_allowed_users = tenant.kaui_allowed_users.map {|au| au.id}

      retrieve_allowed_users_for_current_user.select {|au| !actual_allowed_users.include? au.id }
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
      result = Kaui::Catalog::get_catalog_json(false, effective_date, options) rescue catalog = []

      # convert result to a full hash since dynamic attributes of a class are ignored when converting to json
      result.each do |data|
        plans = []
        data[:plans].each do |plan|
          plans << plan.instance_variables.each_with_object({}) {|var, hash_plan| hash_plan[var.to_s.delete("@")] = plan.instance_variable_get(var) }
        end

        catalog << {:version_date => data[:version_date],
            :currencies => data[:currencies],
            :plans => plans
          }
      end

      {:catalog => catalog }
    end
  end

  def suggest_plugin_name
    json_response do
      message = nil
      entered_plugin_name = params.require(:plugin_name)
      plugin_repository = view_context.plugin_repository

      found_plugin, weights = fuzzy_match(entered_plugin_name, plugin_repository)

      if weights.size > 0
        plugin_anchor = view_context.link_to(weights[0][:plugin_name], '#', id: 'suggested',
                                            data: {
                                                plugin_name: weights[0][:plugin_name],
                                                plugin_key: weights[0][:plugin_key],
                                                plugin_type: weights[0][:plugin_type],
                                            })
        message = "Similar plugin already installed: '#{plugin_anchor}'" if weights[0][:worth_weight].to_f >= 1.0 && weights[0][:installed]
        message = "Did you mean '#{plugin_anchor}'?" if weights[0][:worth_weight].to_f < 1.0 || !weights[0][:installed]
      end
      { suggestion: message, plugin: found_plugin }
    end
  end

  def switch_tenant
    tenant = Kaui::Tenant.find_by_kb_tenant_id(params.require(:kb_tenant_id))

    # Select the tenant, see TenantsController
    session[:kb_tenant_id] = tenant.kb_tenant_id
    session[:kb_tenant_name] = tenant.name
    session[:tenant_id] = tenant.id

    redirect_to admin_tenant_path(tenant.id), :notice => "Tenant was switched to #{tenant.name}"
  end

  private


  def safely_find_tenant_by_id(tenant_id)
    tenant = Kaui::Tenant.find_by_id(tenant_id)
    raise ActiveRecord::RecordNotFound.new('Could not find tenant ' + tenant_id) unless retrieve_tenants_for_current_user.include?(tenant.kb_tenant_id)
    tenant
  end

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

  def set_tenant_if_nil(tenant)

    if session[:kb_tenant_id].nil?
      session[:kb_tenant_id] = tenant.kb_tenant_id
      session[:kb_tenant_name] = tenant.name
      session[:tenant_id] = tenant.id
    end
  end

  def split_camel_dash_underscore_space(data)
    # to_s to handle nil
    data.to_s.split(/(?=[A-Z])|(?=[_])|(?=[-])|(?=[ ])/).select {|member| !member.gsub(/[_-]/,'').strip.empty?}.map { |member| member.gsub(/[_-]/,'').strip.downcase }
  end

  def fuzzy_match(entered_plugin_name, plugin_repository)
    splitted_entered_plugin_name = split_camel_dash_underscore_space(entered_plugin_name)
    worth_of_non_words = 0.5 / splitted_entered_plugin_name.size.to_i

    weights = []

    plugin_repository.each do |plugin|
      return plugin, [] if plugin[:plugin_name] == entered_plugin_name || plugin[:plugin_key] == entered_plugin_name
      weight = { :plugin_name => plugin[:plugin_name], :plugin_key => plugin[:plugin_key],
                 :plugin_type => plugin[:plugin_type], :installed => plugin[:installed], :worth_weight => 0.0 }

      splitted_plugin_name = split_camel_dash_underscore_space(plugin[:plugin_name])
      splitted_entered_plugin_name.each do |entered|
        if splitted_plugin_name.include?(entered)
          weight[:worth_weight] = weight[:worth_weight] + 1.0
        end

        splitted_plugin_name.each do |splitted|
          if entered.chars.all? { |ch| splitted.include?(ch) }
            weight[:worth_weight] = weight[:worth_weight] + worth_of_non_words
            break
          end
        end

        # perform a plugin key search, if weight is zero
        next unless weight[:worth_weight] == 0
        splitted_plugin_key = split_camel_dash_underscore_space(plugin[:plugin_key])

        if splitted_plugin_key.include?(entered)
          weight[:worth_weight] = weight[:worth_weight] + 1.0
        end

        splitted_plugin_key.each do |splitted|
          if entered.chars.all? { |ch| splitted.include?(ch) }
            weight[:worth_weight] = weight[:worth_weight] + worth_of_non_words
            break
          end
        end
      end

      weights << weight if weight[:worth_weight] > 0

    end

    weights.sort! { |a,b| b[:worth_weight] <=> a[:worth_weight] } if weights.size > 1
    return nil, weights
  end

  def fetch_catalog_xml(tenant_id, effective_date)
    current_tenant = safely_find_tenant_by_id(tenant_id)

    options = tenant_options_for_client
    options[:api_key] = current_tenant.api_key
    options[:api_secret] = current_tenant.api_secret

    response = Kaui::Catalog.get_catalog_xml(effective_date, options) rescue response = {}

    catalog_xml = {}
    catalog_xml = response[0][:xml] unless response.blank?

    catalog_xml
  end
end
