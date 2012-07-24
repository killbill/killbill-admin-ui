require 'kaui/product'

class Kaui::SubscriptionsController < Kaui::EngineController
  def index
    if params[:subscription_id].present?
      redirect_to subscription_path(params[:subscription_id])
    end
  end

  def show
    @subscription = Kaui::KillbillHelper.get_subscription(params[:id])
    unless @subscription.present?
      flash[:error] = "No subscription id given or subscription not found"
      redirect_to :back
    end
  end

  def new
    bundle_id = params[:bundle_id]
    @base_subscription = params[:base_subscription]
    @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
    if @base_subscription.present?
      @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription)
    else
      @catalog = Kaui::KillbillHelper::get_available_base_plans()
    end

    @subscription = Kaui::Subscription.new("bundleId" => bundle_id)
  end

  def create
    @base_subscription = params[:base_subscription]
    @subscription = Kaui::Subscription.new(params[:subscription])
    @bundle = Kaui::KillbillHelper::get_bundle(@subscription.bundle_id)
    @plan_name = params[:plan_name]
    if @base_subscription.present?
      @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription)
      @subscription.product_category = "ADD_ON"
    else
      @catalog = Kaui::KillbillHelper::get_available_base_plans()
      @subscription.product_category = "BASE"
    end

    plan = @catalog[@plan_name]
    @subscription.billing_period = plan["billingPeriod"]
    @subscription.product_name = plan["productName"]
    @subscription.price_list = plan["priceListName"]

    begin
      Kaui::KillbillHelper::create_subscription(@subscription)
      redirect_to Kaui.bundle_home_path.call(@bundle.external_key)
    rescue => e
      flash[:error] = e.message
      render :new
    end
  end

  def add_addon
    @base_product_name = params[:base_product_name]

    @bundle_id = params[:bundle_id]
    @product_name = params[:product_name]
    @product_category = params[:product_category]
    @billing_period = params[:billing_period]
    @price_list = params[:price_list]

    @subscription = Kaui::Subscription.new(:bundle_id => @bundle_id,
                                           :product_name => @product_name,
                                           :product_category => @product_category,
                                           :billing_period => @billing_period,
                                           :price_list => @price_list)

    @bundle = Kaui::KillbillHelper.get_bundle(subscription.bundle_id)
    @available_plans = Kaui::KillbillHelper.get_available_addons(params[:base_product_name])
  end

  def edit
    @subscription = Kaui::KillbillHelper.get_subscription(params[:id])
    if @subscription.present?
      bundle_id = params[:bundle_id]
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
      @catalog = Kaui::KillbillHelper::get_available_base_plans
      @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize
      if @subscription.price_list != "DEFAULT"
        @current_plan += " (price list #{@subscription.price_list})"
      end
    else
      flash[:error] = "No subscription id given or subscription not found"
      redirect_to :back
    end
  end

  def update
    if params.has_key?(:subscription) && params[:subscription].has_key?(:subscription_id)
      subscription = Kaui::KillbillHelper.get_subscription(params[:subscription][:subscription_id])
      catalog = Kaui::KillbillHelper::get_available_base_plans
      plan = catalog[params[:plan_name]]
      start_date = params[:start_date]
      subscription.billing_period = plan["billingPeriod"]
      subscription.product_category = plan["productCategory"]
      subscription.product_name = plan["productName"]
      subscription.price_list = plan["priceListName"]
      subscription.subscription_id = params[:subscription][:subscription_id]
      # TODO: need to use entered start_date (or current date if none entered)

      Kaui::KillbillHelper.update_subscription(subscription)

      redirect_to :back
    else
      flash[:error] = "No subscription given"
      redirect_to :back
    end
  end

  def reinstate
    subscription_id = params[:id]
    if subscription_id.present?
      success = Kaui::KillbillHelper.reinstate_subscription(subscription_id, current_user)
      if success
        flash[:info] = "Subscription reinstated"
      else
        flash[:error] = "Error reinstating subscription"
      end
      redirect_to :back
    else
      flash[:error] = "No subscription id given"
    end
  end

  def destroy
    subscription_id = params[:id]
    if subscription_id.present?
      Kaui::KillbillHelper.delete_subscription(subscription_id)
      redirect_to :back
    else
      flash[:error] = "No subscription id given"
    end
  end
end