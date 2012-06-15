require 'kaui/product'

class Kaui::SubscriptionsController < ApplicationController
  def index
  end

  def show
    @subscription = Kaui::KillbillHelper.get_subscription(params[:id])
    unless @subscription.present?
      flash[:error] = "No subscription id given or subscription not found"
      redirect_to :back
    end
  end

  def new
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
  end

  def create
    subscription = Kaui::Subscription.new(params[:subscription])
    bundle = Kaui::KillbillHelper.get_bundle(subscription.bundle_id)

    Kaui::KillbillHelper::create_subscription(subscription)
    redirect_to account_timeline_path(:id => bundle.account_id)
  end

  def edit
    @subscription = Kaui::KillbillHelper.get_subscription(params[:id])
    unless @subscription.present?
      flash[:error] = "No subscription id given or subscription not found"
      redirect_to :back
    end
    @products = Kaui::BASE_PRODUCTS
  end

  def update
    if params.has_key?(:subscription) && params[:subscription].has_key?(:subscription_id)
      subscription = Kaui::KillbillHelper.get_subscription(params[:subscription][:subscription_id])
      product_id = params[:subscription][:product_name]
      products = Kaui::BASE_PRODUCTS.select{|p| p.id == product_id}
      unless products.empty?
        subscription.product_name = products[0].product_name
        subscription.billing_period = products[0].billing_period
        subscription.start_date = params[:subscription][:start_date]
        Kaui::KillbillHelper.update_subscription(subscription)
      end
      redirect_to :action => :show, :id => subscription.subscription_id
    else
      flash[:error] = "No subscription given"
      redirect_to :back
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