require 'kaui/product'

class Kaui::SubscriptionsController < Kaui::EngineController
  def index
    if params[:subscription_id].present?
      redirect_to kaui_engine.subscription_path(params[:subscription_id])
    end
  end

  def show
    begin
      @subscription = Kaui::KillbillHelper.get_subscription(params[:id], options_for_klient)
      unless @subscription.present?
        flash[:error] = "No subscription id given or subscription not found"
        redirect_to :back
      end

      @account = Kaui::KillbillHelper::get_account_by_bundle_id(@subscription.bundle_id, options_for_klient)
      unless @account.present?
        flash[:error] = "Unable to retrieve account for bundle #{@subscription.bundle_id}"
        redirect_to :back
      end
    rescue => e
      flash.now[:error] = "Error while getting subscription information: #{as_string(e)}"
    end
  end

  def new
    @account_id = params[:account_id]
    bundle_id = params[:bundle_id]
    @base_subscription = params[:base_subscription]
    @product_category = params[:product_category]
    begin

      if @product_category == "ADD_ON"
        @bundle = Kaui::KillbillHelper::get_bundle(bundle_id, options_for_klient)
        @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription, options_for_klient)
      elsif @product_category == "BASE"
        @catalog = Kaui::KillbillHelper::get_available_base_plans(options_for_klient)
      end
    rescue => e
      flash.now[:error] = "Error while trying to start new subscription creation: #{as_string(e)}"
    end
    @subscription = Kaui::Subscription.new("bundleId" => bundle_id, "accountId" => @account_id, "product_category" => @product_category)
  end

  def create

    @subscription = Kaui::Subscription.new(params[:subscription])

    @plan_name = params[:plan_name]

    begin
      if @subscription.product_category == "ADD_ON"
        @base_subscription = params[:base_subscription]
        @bundle = Kaui::KillbillHelper::get_bundle(@subscription.bundle_id, options_for_klient)
        @catalog = Kaui::KillbillHelper::get_available_addons(@base_subscription, options_for_klient)
        @subscription.account_id = @bundle.account_id
      else
        @catalog = Kaui::KillbillHelper::get_available_base_plans(options_for_klient)
        @subscription.external_key = params[:external_key]
      end

      plan = @catalog[@plan_name]
      @subscription.billing_period = plan["billingPeriod"]
      @subscription.product_name = plan["productName"]
      @subscription.price_list = plan["priceListName"]

      res = Kaui::KillbillHelper::create_subscription(@subscription, current_user, params[:reason], params[:comment], options_for_klient)

      redirect_to Kaui.bundle_home_path.call(res.bundle_id)
    rescue => e
      flash.now[:error] = "Error while creating the new subscription: #{as_string(e)}"
      render :new
    end
  end

  def add_addon
    @base_product_name = params[:base_product_name]

    @account_id = params[:account_id]
    @bundle_id = params[:bundle_id]
    @product_name = params[:product_name]
    @product_category = params[:product_category]
    @billing_period = params[:billing_period]
    @price_list = params[:price_list]

    begin
      @subscription = Kaui::Subscription.new(:account_id => @account_id,
                                             :bundle_id => @bundle_id,
                                             :product_name => @product_name,
                                             :product_category => @product_category,
                                             :billing_period => @billing_period,
                                             :price_list => @price_list)

      @bundle = Kaui::KillbillHelper.get_bundle(subscription.bundle_id, options_for_klient)
      @available_plans = Kaui::KillbillHelper.get_available_addons(params[:base_product_name], options_for_klient)
    rescue => e
      flash.now[:error] = "Error while adding an addon: #{as_string(e)}"
    end
  end

  def edit
    begin
      @subscription = Kaui::KillbillHelper.get_subscription(params[:id], options_for_klient)

      if @subscription.present?
        @bundle = Kaui::KillbillHelper::get_bundle(@subscription.bundle_id, options_for_klient)
        @account = Kaui::KillbillHelper::get_account(@bundle.account_id, false, false, options_for_klient)
        @catalog = Kaui::KillbillHelper::get_available_base_plans(options_for_klient)

        @current_plan = "#{@subscription.product_name} #{@subscription.billing_period}".humanize

        if @subscription.price_list != "DEFAULT"
          @current_plan += " (price list #{@subscription.price_list})"
        end
      else
        flash[:error] = "No subscription id given or subscription not found"
        redirect_to :back
      end
    rescue => e
      flash.now[:error] = "Error while editing subscription: #{as_string(e)}"
    end
  end

  def update
    if params.has_key?(:subscription) && params[:subscription].has_key?(:subscription_id)

      begin
        subscription = Kaui::KillbillHelper::get_subscription(params[:subscription][:subscription_id], options_for_klient)
        bundle = Kaui::KillbillHelper::get_bundle(subscription.bundle_id, options_for_klient)
        catalog = Kaui::KillbillHelper::get_available_base_plans(options_for_klient)

        plan = catalog[params[:plan_name]]
        requested_date = params[:requested_date]
        policy = params[:policy]

        subscription.billing_period = plan["billingPeriod"]
        subscription.product_category = plan["productCategory"]
        subscription.product_name = plan["productName"]
        subscription.price_list = plan["priceListName"]
        subscription.subscription_id = params[:subscription][:subscription_id]

        Kaui::KillbillHelper::update_subscription(subscription, requested_date, policy, current_user, params[:reason], params[:comment], options_for_klient)
      rescue => e
        flash[:error] = "Error while updating subscription: #{as_string(e)}"
      end
    else
      flash[:error] = "No subscription given"
    end
    redirect_to Kaui.bundle_home_path.call(bundle.bundle_id)
  end

  def destroy


    subscription_id = params[:id]

    puts "calling destroy id = #{subscription_id}"

    if subscription_id.present?
      begin

        puts "current_user = #{current_user}"

        Kaui::KillbillHelper::delete_subscription(subscription_id, current_user, params[:reason], params[:comment], params[:policy], options_for_klient)
      rescue => e
        flash[:error] = "Error while canceling subscription: #{as_string(e)}"
      end
    else
      flash[:error] = "No subscription id given"
    end
    redirect_to :back
  end
end
