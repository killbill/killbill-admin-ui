class Kaui::SubscriptionsController < Kaui::EngineController

  def index
  end

  def new
    @base_product_name = params[:base_product_name]
    @subscription      = Kaui::Subscription.new(:bundle_id        => params[:bundle_id],
                                                :account_id       => params[:account_id],
                                                :product_category => params[:product_category] || 'BASE')

    begin
      if @subscription.product_category == 'ADD_ON'
        @bundle       = Kaui::Bundle::find_by_id(@subscription.bundle_id, options_for_klient)
        plans_details = Kaui::Catalog::available_addons(@base_product_name, options_for_klient)
      else
        plans_details = Kaui::Catalog::available_base_plans(options_for_klient)
      end
      @plans = plans_details.map { |p| p.plan }
    rescue => e
      flash.now[:error] = "Error while trying to start new subscription creation: #{as_string(e)}"
      render :action => :index
    end
  end

  def create
    @subscription = Kaui::Subscription.new(params[:subscription].delete_if { |key, value| value.blank? })

    begin
      if @subscription.product_category == 'ADD_ON'
        @bundle       = Kaui::Bundle::find_by_id(@subscription.bundle_id, options_for_klient)
        plans_details = Kaui::Catalog::available_addons(params[:base_product_name], options_for_klient)
      else
        plans_details = Kaui::Catalog::available_base_plans(options_for_klient)
      end

      plan_details                 = plans_details.find { |p| p.plan == params[:plan_name] }
      @subscription.billing_period = plan_details.final_phase_billing_period
      @subscription.product_name   = plan_details.product
      @subscription.price_list     = plan_details.price_list

      @subscription = @subscription.create(current_user, params[:reason], params[:comment], options_for_klient)
      redirect_to bundle_path(@subscription.bundle_id), :notice => 'Subscription was successfully created'
    rescue => e
      @plans            = plans_details.nil? ? [] : plans_details.map { |p| p.plan }
      flash.now[:error] = "Error while creating the subscription: #{as_string(e)}"
      render :new
    end
  end

  def show
    begin
      @subscription = Kaui::Subscription.find_by_id(params[:id], options_for_klient)
      # Need to retrieve the account for the timezone
      @account      = Kaui::Account::find_by_id(@subscription.account_id, false, false, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while getting subscription information: #{as_string(e)}"
      render :action => :index
    end
  end

  def edit
    begin
      @subscription = Kaui::Subscription.find_by_id(params[:id], options_for_klient)
      plans_details = Kaui::Catalog::available_base_plans(options_for_klient)
      @plans        = plans_details.map { |p| p.plan }

      @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize
      if @subscription.price_list != 'DEFAULT'
        @current_plan += " (price list #{@subscription.price_list})"
      end
    rescue => e
      flash.now[:error] = "Error while editing subscription: #{as_string(e)}"
    end
  end

  def update
    requested_date      = params[:requested_date] unless params[:requested_date].blank?
    billing_policy      = params[:policy] unless params[:policy].blank?
    wait_for_completion = params[:wait_for_completion] == '1'

    subscription = Kaui::Subscription.new(:subscription_id => params[:id])

    begin
      plans_details    = Kaui::Catalog::available_base_plans(options_for_klient)
      new_plan_details = plans_details.find { |p| p.plan == params[:plan_name] }

      subscription.change_plan({
                                   :productName   => new_plan_details.product,
                                   :billingPeriod => new_plan_details.final_phase_billing_period,
                                   :priceList     => new_plan_details.price_list
                               },
                               current_user,
                               params[:reason],
                               params[:comment],
                               requested_date,
                               billing_policy,
                               wait_for_completion,
                               options_for_klient)
      flash[:notice] = 'Subscription plan successfully changed'
    rescue => e
      flash[:error] = "Error while changing subscription plan: #{as_string(e)}"
    end

    redirect_to subscription_path(subscription.subscription_id)
  end

  def destroy
    requested_date                 = params[:requested_date] unless params[:requested_date].blank?
    entitlement_policy             = params[:policy] unless params[:policy].blank?
    billing_policy                 = entitlement_policy
    # true by default
    use_requested_date_for_billing = (params[:use_requested_date_for_billing] || '1') == '1'

    subscription = Kaui::Subscription.new(:subscription_id => params[:id])

    begin
      subscription.cancel(current_user, params[:reason], params[:comment], requested_date, entitlement_policy, billing_policy, use_requested_date_for_billing, options_for_klient)
      flash[:notice] = 'Subscription was successfully cancelled'
    rescue => e
      flash[:error] = "Error while canceling subscription: #{as_string(e)}"
    end

    redirect_to subscription_path(subscription.subscription_id)
  end

  def reinstate
    subscription = Kaui::Subscription.new(:subscription_id => params[:id])

    begin
      subscription.uncancel(current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = 'Subscription was successfully reinstated'
    rescue => e
      flash[:error] = "Error while reinstating subscription: #{as_string(e)}"
    end

    redirect_to subscription_path(subscription.subscription_id)
  end
end
