class Kaui::SubscriptionsController < Kaui::EngineController

  def new
    @base_product_name = params[:base_product_name]
    @subscription = Kaui::Subscription.new(:bundle_id => params[:bundle_id],
                                           :account_id => params[:account_id],
                                           :product_category => params[:product_category] || 'BASE')

    @bundle, plans_details = lookup_bundle_and_plan_details(@subscription, @base_product_name)
    @plans = plans_details.map { |p| p.plan }

    if @plans.empty?
      if @subscription.product_category == 'BASE'
        flash[:error] = 'No available plan'
      else
        flash[:error] = "No available add-on for product #{@base_product_name}"
      end
      redirect_to kaui_engine.account_bundles_path(@subscription.account_id), :error => 'No available plan'
    end
  end

  def create
    plan_name = params.require(:plan_name)
    @base_product_name = params[:base_product_name]
    @subscription = Kaui::Subscription.new(params.require(:subscription).delete_if { |key, value| value.blank? })

    begin
      @bundle, plans_details = lookup_bundle_and_plan_details(@subscription, @base_product_name)

      plan_details = plans_details.find { |p| p.plan == plan_name }
      raise "Unable to find plan #{plan_name}" if plan_details.nil?

      @subscription.plan_name = plan_name
      requested_date = params[:type_change] == "DATE" ? params[:requested_date].presence : nil

      # un-set product_category since is not needed if plan name exist
      @subscription.product_category = nil
      @subscription = @subscription.create(current_user.kb_username, params[:reason], params[:comment], requested_date, false, options_for_klient)
      redirect_to kaui_engine.account_bundles_path(@subscription.account_id), :notice => 'Subscription was successfully created'
    rescue => e
      @plans = plans_details.nil? ? [] : plans_details.map { |p| p.plan }
      flash.now[:error] = "Error while creating the subscription: #{as_string(e)}"
      render :new
    end
  end

  def edit
    @subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)
    _, plans_details = lookup_bundle_and_plan_details(@subscription)
    # Use a Set to deal with multiple pricelists
    @plans = Set.new.merge(plans_details.map { |p| p.plan })

    @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize
    @current_plan += " (price list #{@subscription.price_list})" if @subscription.price_list != 'DEFAULT'
  end

  def update

    plan_name = params.require(:plan_name)

    requested_date = params[:type_change] == "DATE" ? params[:requested_date].presence : nil
    billing_policy = params[:type_change] == "POLICY" ? params[:policy].presence : nil

    wait_for_completion = params[:wait_for_completion] == '1'

    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)

    subscription.change_plan({
                                 :planName => plan_name
                             },
                             current_user.kb_username,
                             params[:reason],
                             params[:comment],
                             requested_date,
                             billing_policy,
                             nil,
                             wait_for_completion,
                             options_for_klient)

    redirect_to kaui_engine.account_bundles_path(subscription.account_id), :notice => 'Subscription plan successfully changed'
  end

  def destroy
    requested_date = params[:requested_date].presence
    billing_policy = params[:policy].presence
    # START_OF_TERM is *not* a valid entitlement_policy and so would default to IMMEDIATE
    entitlement_policy = billing_policy && billing_policy == 'START_OF_TERM' ? 'IMMEDIATE' : billing_policy

    # true by default
    use_requested_date_for_billing = (params[:use_requested_date_for_billing] || '1') == '1'

    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)

    subscription.cancel(current_user.kb_username, params[:reason], params[:comment], requested_date, entitlement_policy, billing_policy, use_requested_date_for_billing, options_for_klient)

    redirect_to kaui_engine.account_bundles_path(subscription.account_id), :notice => 'Subscription was successfully cancelled'
  end

  def reinstate
    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)

    subscription.uncancel(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to kaui_engine.account_bundles_path(subscription.account_id), :notice => 'Subscription was successfully reinstated'
  end

  def edit_bcd
    @subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)
  end

  def update_bcd
    input_subscription = params.require(:subscription)
    subscription =  Kaui::Subscription.new
    subscription.subscription_id = params.require(:id)
    subscription.bill_cycle_day_local = input_subscription["bill_cycle_day_local"]

    effective_from_date = params["effective_from_date"]

    subscription.update_bcd(current_user.kb_username, params[:reason], params[:comment], effective_from_date, nil, options_for_klient)
    redirect_to kaui_engine.account_bundles_path(input_subscription["account_id"]), :notice => 'Subscription BCD was successfully changed'
  end

  def show
    restful_show
  end

  def restful_show
    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)
    redirect_to kaui_engine.account_bundles_path(subscription.account_id)
  end

  def validate_external_key
    json_response do
      external_key = params.require(:external_key)

      begin
        bundle = Kaui::Bundle.find_by_external_key(external_key, false, options_for_klient)
      rescue KillBillClient::API::NotFound
        bundle = nil
      end

      { :is_found => !bundle.nil? }
    end
  end

  def update_tags
    subscription_id = params.require(:id)
    subscription = Kaui::Subscription.find_by_id(subscription_id, options_for_klient)

    tags = []
    params.each do |tag|
      tag_info = tag.split('_')
      next if tag_info.size != 2 or tag_info[0] != 'tag'
      tags << tag_info[1]
    end

    Kaui::Tag.set_for_subscription(subscription_id, tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_bundles_path(subscription.account_id), :notice => 'Subscription tags successfully set'
  end

  private

  def lookup_bundle_and_plan_details(subscription, base_product_name = nil)
    if subscription.product_category == 'ADD_ON'
      bundle = Kaui::Bundle.find_by_id(@subscription.bundle_id, options_for_klient)
      if base_product_name.blank?
        bundle.subscriptions.each do |sub|
          if sub.product_category == 'BASE'
            base_product_name = sub.product_name
            break
          end
        end
      end
      plans_details = Kaui::Catalog.available_addons(base_product_name, options_for_klient)
    else
      bundle = nil
      plans_details = catalog_plans(subscription.product_category == 'BASE' ? nil : subscription.product_category)
    end
    [bundle, plans_details]
  end

  def catalog_plans(product_category = nil)
    if product_category == 'BASE'
      return Kaui::Catalog.available_base_plans(options_for_klient)
    else
      options = options_for_klient

      catalog = Kaui::Catalog.get_tenant_catalog_json( DateTime.now.to_s, options)

      return [] if catalog.blank?

      plans = []
      catalog[catalog.size - 1].products.each do |product|
        next if product.type == 'ADD_ON' || (!product_category.nil? && product.type != product_category)
        product.plans.each do |plan|
          class << plan
            attr_accessor :plan
          end
          plan.plan = plan.name

          plans << plan
        end
      end

      return plans

    end
  end
end
