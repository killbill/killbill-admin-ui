class Kaui::AccountsController < Kaui::EngineController

  def index
  end

  def pagination
    search_key = params[:sSearch]
    offset     = params[:iDisplayStart] || 0
    limit      = params[:iDisplayLength] || 10

    accounts = Kaui::Account.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho                => params[:sEcho],
        :iTotalRecords        => accounts.pagination_max_nb_records,
        :iTotalDisplayRecords => accounts.pagination_total_nb_records,
        :aaData               => []
    }

    accounts.each do |account|
      json[:aaData] << [
          view_context.link_to(account.account_id, view_context.url_for(:action => :show, :id => account.account_id)),
          account.name,
          account.external_key,
          account.currency,
          account.city,
          account.country
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def new
    @account = Kaui::Account.new
  end

  def create
    @account                          = Kaui::Account.new(params[:account].delete_if { |key, value| value.blank? })

    # Transform "1" into boolean
    @account.is_migrated              = @account.is_migrated == '1'
    @account.is_notified_for_invoices = @account.is_notified_for_invoices == '1'

    begin
      @account = @account.create(current_user, params[:reason], params[:comment], options_for_klient)
      redirect_to account_path(@account.account_id), :notice => 'Account was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating account: #{as_string(e)}"
      render :action => :new
    end
  end

  def show
    begin
      @account       = Kaui::Account::find_by_id_or_key(params[:id], true, true, options_for_klient)
      @overdue_state = @account.overdue(options_for_klient)
      @bundles       = @account.bundles(options_for_klient)

      @tags            = Kaui::Tag.find_all_sorted_by_account_id(@account.account_id, false, 'NONE', options_for_klient)
      @account_emails  = Kaui::AccountEmail.where({:account_id => @account.account_id}, options_for_klient)
      @payment_methods = Kaui::PaymentMethod.find_non_external_by_account_id(@account.account_id, true, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while retrieving account information: #{as_string(e)}"
      render :action => :index and return
    end

    @subscriptions_by_bundle_id = {}
    @bundles.each do |bundle|
      @subscriptions_by_bundle_id[bundle.bundle_id.to_s] = (@subscriptions_by_bundle_id[bundle.bundle_id.to_s] || []) + bundle.subscriptions
    end
  end

  def set_default_payment_method
    account_id        = params[:id]
    payment_method_id = params[:payment_method_id]

    begin
      Kaui::PaymentMethod.set_default(payment_method_id, account_id, current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = "Successfully set #{payment_method_id} as default"
    rescue => e
      flash[:error] = "Error while setting payment method #{payment_method_id} as default: #{as_string(e)}"
    end

    redirect_to account_path(account_id)
  end

  def toggle_email_notifications
    account = Kaui::Account.new(:account_id => params[:id], :is_notified_for_invoices => params[:is_notified])

    begin
      account.update_email_notifications(current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = 'Email preferences updated'
    rescue => e
      flash[:error] = "Error while setting email notifications: #{as_string(e)}"
    end

    redirect_to account_path(account.account_id)
  end

  def pay_all_invoices
    payment = Kaui::InvoicePayment.new(:account_id => params[:id])

    begin
      payment.bulk_create(params[:is_external_payment], current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = 'Successfully triggered a payment for all unpaid invoices'
    rescue => e
      flash[:error] = "Error while triggering payments: #{as_string(e)}"
    end

    redirect_to account_path(payment.account_id)
  end
end
