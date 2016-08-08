class Kaui::SubscriptionsController < Kaui::EngineController

  def new
    @base_product_name = params[:base_product_name]
    @subscription = Kaui::Subscription.new(:bundle_id => params[:bundle_id],
                                           :account_id => params[:account_id],
                                           :product_category => params[:product_category] || 'BASE')

    @bundle, plans_details = lookup_bundle_and_plan_details(@subscription)
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
      @bundle, plans_details = lookup_bundle_and_plan_details(@subscription)

      plan_details = plans_details.find { |p| p.plan == plan_name }
      raise "Unable to find plan #{plan_name}" if plan_details.nil?

      @subscription.billing_period = plan_details.final_phase_billing_period
      @subscription.product_name = plan_details.product
      @subscription.price_list = plan_details.price_list

      requested_date = params[:type_change] == "DATE" ? params[:requested_date].presence : nil
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
    @plans = plans_details.map { |p| p.plan }

    @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize
    @current_plan += " (price list #{@subscription.price_list})" if @subscription.price_list != 'DEFAULT'
  end

  def update

    plan_name = params.require(:plan_name)

    requested_date = params[:type_change] == "DATE" ? params[:requested_date].presence : nil
    billing_policy = params[:type_change] == "POLICY" ? params[:policy].presence : nil

    wait_for_completion = params[:wait_for_completion] == '1'

    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)
    plans_details = Kaui::Catalog::available_base_plans(options_for_klient)
    new_plan_details = plans_details.find { |p| p.plan == plan_name }
    raise "Unable to find plan #{plan_name}" if new_plan_details.nil?

    subscription.change_plan({
                                 :productName => new_plan_details.product,
                                 :billingPeriod => new_plan_details.final_phase_billing_period,
                                 :priceList => new_plan_details.price_list
                             },
                             current_user.kb_username,
                             params[:reason],
                             params[:comment],
                             requested_date,
                             billing_policy,
                             wait_for_completion,
                             options_for_klient)

    redirect_to kaui_engine.account_bundles_path(subscription.account_id), :notice => 'Subscription plan successfully changed'
  end

  def destroy
    requested_date = params[:requested_date].presence
    entitlement_policy = params[:policy].presence
    billing_policy = entitlement_policy
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

  def show
    restful_show
  end

  def restful_show
    subscription = Kaui::Subscription.find_by_id(params.require(:id), options_for_klient)
    redirect_to kaui_engine.account_bundles_path(subscription.account_id)
  end

  private

  def lookup_bundle_and_plan_details(subscription)
    if subscription.product_category == 'ADD_ON'
      bundle = Kaui::Bundle.find_by_id(@subscription.bundle_id, options_for_klient)
      plans_details = Kaui::Catalog.available_addons(@base_product_name, options_for_klient)
    else
      bundle = nil
      plans_details = Kaui::Catalog.available_base_plans(options_for_klient)
    end
    [bundle, plans_details]
  end
end
