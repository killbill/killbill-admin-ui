class Kaui::AccountsController < Kaui::EngineController

  def index
    @search_query = params[:q]
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      Kaui::Account.list_or_search(search_key, offset, limit, options_for_klient)
    end

    data_extractor = lambda do |account, column|
      [
          account.name,
          account.account_id,
          account.external_key,
          account.account_balance,
          account.city,
          account.country
      ][column]
    end

    formatter = lambda do |account|
      [
          view_context.link_to(account.name, view_context.url_for(:action => :show, :account_id => account.account_id)),
          view_context.truncate_uuid(account.account_id),
          account.external_key,
          view_context.humanized_money_with_symbol(account.balance_to_money),
          account.city,
          account.country
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def new
    @account = Kaui::Account.new
  end

  def create
    @account = Kaui::Account.new(params.require(:account).delete_if { |key, value| value.blank? })

    # Transform "1" into boolean
    @account.is_migrated = @account.is_migrated == '1'
    @account.is_notified_for_invoices = @account.is_notified_for_invoices == '1'

    begin
      @account = @account.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to account_path(@account.account_id), :notice => 'Account was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating account: #{as_string(e)}"
      render :action => :new
    end
  end

  def show
    @account = Kaui::Account::find_by_id_or_key(params.require(:account_id), true, true, options_for_klient)

    fetch_overdue_state = lambda { @overdue_state = @account.overdue(options_for_klient) }
    fetch_account_tags = lambda { @tags = @account.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b } }
    fetch_account_emails = lambda { @account_emails = Kaui::AccountEmail.find_all_sorted_by_account_id(@account.account_id, 'NONE', options_for_klient) }
    fetch_payment_methods = lambda do
      begin
        @payment_methods = Kaui::PaymentMethod.find_non_external_by_account_id(@account.account_id, true, options_for_klient)
      rescue KillBillClient::API::BadRequest
        # Maybe the plugin(s) are not registered?
        @payment_methods = Kaui::PaymentMethod.find_non_external_by_account_id(@account.account_id, false, options_for_klient)
      end
    end

    run_in_parallel fetch_overdue_state, fetch_account_tags, fetch_account_emails, fetch_payment_methods
  end

  def set_default_payment_method
    account_id = params.require(:account_id)
    payment_method_id = params.require(:payment_method_id)

    Kaui::PaymentMethod.set_default(payment_method_id, account_id, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to account_path(account_id), :notice => "Successfully set #{payment_method_id} as default"
  end

  def toggle_email_notifications
    account = Kaui::Account.new(:account_id => params.require(:account_id), :is_notified_for_invoices => params[:is_notified] == 'true')

    account.update_email_notifications(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to account_path(account.account_id), :notice => 'Email preferences updated'
  end

  def pay_all_invoices
    payment = Kaui::InvoicePayment.new(:account_id => params.require(:account_id))

    payment.bulk_create(params[:is_external_payment] == 'true', current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to account_path(payment.account_id), :notice => 'Successfully triggered a payment for all unpaid invoices'
  end
end
