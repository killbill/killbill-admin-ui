require 'rest_client'
require 'json'

class Kaui::AccountsController < Kaui::EngineController
  def index
    if params[:account_id].present?
      redirect_to account_path(params[:account_id])
    end
  end

  def show
    key = params[:id]
    if key.present?
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        @account = Kaui::KillbillHelper::get_account(key, true)
      else
        @account = Kaui::KillbillHelper::get_account_by_external_key(key, true)
      end

      if @account.present?
        @payment_methods = Kaui::KillbillHelper::get_payment_methods(@account.account_id)
        @bundles = Kaui::KillbillHelper::get_bundles(@account.account_id)
        @subscriptions_by_bundle_id = {}

        @bundles.each do |bundle|
          subscriptions = Kaui::KillbillHelper::get_subscriptions_for_bundle(bundle.bundle_id)
          if subscriptions.present?
            @subscriptions_by_bundle_id[bundle.bundle_id.to_s] = (@subscriptions_by_bundle_id[bundle.bundle_id.to_s] || []) + subscriptions
          end
        end
      else
        flash[:error] = "Account #{@account_id} not found"
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end

  def payment_methods
    @account_id = params[:id]
    if @account_id.present?
      @payment_methods = Kaui::KillbillHelper::get_payment_methods(@account_id)
      unless @payment_methods.is_a?(Array)
        flash[:notice] = "No payment methods for account_id '#{@account_id}'"
        redirect_to :action => :index
        return
      end
    else
      flash[:notice] = "No account_id given"
    end
  end

  def add_payment_method
    account_id = params[:id]
    @account = Kaui::KillbillHelper::get_account(account_id)
    if @account.nil?
      flash[:error] = "Account not found for id #{account_id}"
      redirect_to :back
    else
      render "kaui/payment_methods/new"
    end
  end

  def do_add_payment_method
    account_id = params[:id]
    @account = Kaui::KillbillHelper::get_account(account_id)

    # Implementation example using standard credit card fields
    @card_type = params[:card_type]
    @card_holder_name = params[:card_holder_name]
    @expiration_year = params[:expiration_year]
    @expiration_month = params[:expiration_month]
    @credit_card_number = params[:credit_card_number]
    @address1 = params[:address1]
    @address2 = params[:address2]
    @city = params[:city]
    @country = params[:country]
    @postal_code = params[:postal_code]
    @state = params[:state]
    @is_default = params[:is_default]
    @reason = params[:reason]
    @comment = params[:comment]

    if @account.present?
      properties = [ Kaui::PluginInfoProperty.new('key' => 'type', 'value' => 'CreditCard'),
                     Kaui::PluginInfoProperty.new('key' => 'cardType', 'value' => @card_type),
                     Kaui::PluginInfoProperty.new('key' => 'cardHolderName', 'value' => @card_holder_name),
                     Kaui::PluginInfoProperty.new('key' => 'expirationDate', 'value' => "#{@expiration_year}-#{@expiration_month}"),
                     Kaui::PluginInfoProperty.new('key' => 'maskNumber', 'value' => @credit_card_number),
                     Kaui::PluginInfoProperty.new('key' => 'address1', 'value' => @address1),
                     Kaui::PluginInfoProperty.new('key' => 'address2', 'value' => @address2),
                     Kaui::PluginInfoProperty.new('key' => 'city', 'value' => @city),
                     Kaui::PluginInfoProperty.new('key' => 'country', 'value' => @country),
                     Kaui::PluginInfoProperty.new('key' => 'postalCode', 'value' => @postal_code),
                     Kaui::PluginInfoProperty.new('key' => 'state', 'value' => @state) ]

      plugin_info = Kaui::PluginInfo.new('properties' => properties)
      payment_method = Kaui::PaymentMethod.new('accountId' => @account.account_id,
                                               'isDefault' => @is_default == 1,
                                               'pluginName' => Kaui.creditcard_plugin_name.call,
                                               'pluginInfo' => plugin_info)

      success = Kaui::KillbillHelper::add_payment_method(payment_method, current_user, @reason, @comment)

      if success
        flash[:info] = "Payment method created"
        redirect_to account_timeline_path(@account.account_id)
        return
      else
        flash[:error] = "Error while adding payment method"
      end
    end
    render "kaui/payment_methods/new"
  end

  def set_default_payment_method
    @account_id = params[:id]
    @payment_method_id = params[:payment_method_id]
    if @account_id.present? && @payment_method_id.present?
      @payment_methods = Kaui::KillbillHelper::set_payment_method_as_default(@account_id, @payment_method_id)
    else
      flash[:notice] = "No account_id or payment_method_id given"
    end
    redirect_to :back
  end
end
