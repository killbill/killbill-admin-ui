require 'rest_client'
require 'json'

class Kaui::AccountsController < Kaui::EngineController
  def index
    if params[:account_id].present?
      redirect_to kaui_engine.account_path(params[:account_id])
    end
  end

  def show
    key = params[:id]
    if key.present?
      # Remove extra whitespaces
      key.strip!

      begin
        @account = Kaui::KillbillHelper::get_account_by_key(key, true)
      rescue URI::InvalidURIError => e
        flash[:error] = "Error while retrieving the account for #{key}: #{e.message}"
        render :action => :index and return
      rescue => e
        flash[:error] = "Error while retrieving the account for #{key}: #{e.message} #{e.response}"
        render :action => :index and return
      end

      if @account.present? and @account.is_a? Kaui::Account
        begin
          @tags = Kaui::KillbillHelper::get_tags_for_account(@account.account_id).sort
          @account_emails = Kaui::AccountEmail.where(:account_id => @account.account_id)
          @payment_methods = Kaui::KillbillHelper::get_payment_methods(@account.account_id)
          @bundles = Kaui::KillbillHelper::get_bundles(@account.account_id)
          @subscriptions_by_bundle_id = {}

          @bundles.each do |bundle|
            subscriptions = Kaui::KillbillHelper::get_subscriptions_for_bundle(bundle.bundle_id)
            if subscriptions.present?
              @subscriptions_by_bundle_id[bundle.bundle_id.to_s] = (@subscriptions_by_bundle_id[bundle.bundle_id.to_s] || []) + subscriptions
            end
          end
        rescue => e
          flash[:error] = "Error while retrieving account information for account: #{e.message} #{e.response}"
        end
      else
        flash[:error] = "Account #{@account_id} not found: #{@account}"
        render :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end

  def payment_methods
    @account_id = params[:id]
    if @account_id.present?
      begin
        @payment_methods = Kaui::KillbillHelper::get_payment_methods(@account_id)
      rescue => e
        flash[:error] = "Error while getting payment methods: #{e.message} #{e.response}"
      end
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
    begin
      @account = Kaui::KillbillHelper::get_account(account_id)
    rescue => e
      flash[:error] = "Error while adding payment methods: #{e.message} #{e.response}"
    end
    if @account.nil?
      flash[:error] = "Account not found for id #{account_id}"
      redirect_to :back
    else
      render "kaui/payment_methods/new"
    end
  end

  def do_add_payment_method
    account_id = params[:id]
    begin
      @account = Kaui::KillbillHelper::get_account(account_id)
    rescue => e
      flash[:error] = "Error while adding payment method: #{e.message} #{e.response}"
    end

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

      begin
        Kaui::KillbillHelper::add_payment_method(payment_method, current_user, @reason, @comment)
        flash[:info] = "Payment method created"
        redirect_to kaui_engine.account_timeline_path(@account.account_id)
        return
      rescue => e
        flash[:error] = "Error while adding payment method #{invoice_id}: #{e.message} #{e.response}"
      end
    end
    render "kaui/payment_methods/new"
  end

  def set_default_payment_method
    @account_id = params[:id]
    @payment_method_id = params[:payment_method_id]
    if @account_id.present? && @payment_method_id.present?
      begin
        @payment_methods = Kaui::KillbillHelper::set_payment_method_as_default(@account_id, @payment_method_id)
      rescue => e
        flash[:error] = "Error while setting payment method as default #{invoice_id}: #{e.message} #{e.response}"
      end
    else
      flash[:notice] = "No account_id or payment_method_id given"
    end
    redirect_to :back
  end

  def toggle_email_notifications
    begin
      @account = Kaui::KillbillHelper::update_email_notifications(params[:id], params[:is_notified])
      flash[:notice] = "Email preferences updated"
      redirect_to :back
    rescue => e
      flash[:error] = "Error while switching email notifications #{invoice_id}: #{e.message} #{e.response}"
    end
  end
end
