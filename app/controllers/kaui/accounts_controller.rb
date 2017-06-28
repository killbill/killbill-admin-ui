class Kaui::AccountsController < Kaui::EngineController

  def index
    @search_query = params[:q]

    if params[:fast] == '1' && !@search_query.blank?
      account = Kaui::Account.list_or_search(@search_query, -1, 1, options_for_klient).first
      if account.nil?
        flash[:error] = "No account matches \"#{@search_query}\""
        redirect_to kaui_engine.home_path and return
      else
        redirect_to kaui_engine.account_path(account.account_id) and return
      end
    end

    @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
    @offset = params[:offset] || 0
    @limit = params[:limit] || 50

    @max_nb_records = @search_query.blank? ? Kaui::Account.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
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
          view_context.link_to(account.name || '(not set)', view_context.url_for(:action => :show, :account_id => account.account_id)),
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
    # Re-fetch the account with balance and CBA
    @account = Kaui::Account::find_by_id_or_key(params.require(:account_id), true, true, options_for_klient)

    fetch_overdue_state = lambda { @overdue_state = @account.overdue(options_for_klient) }
    fetch_account_tags = lambda { @tags = @account.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b } }
    fetch_account_emails = lambda { @account_emails = Kaui::AccountEmail.find_all_sorted_by_account_id(@account.account_id, 'NONE', options_for_klient) }
    fetch_payment_methods = lambda { @payment_methods = Kaui::PaymentMethod.find_all_safely_by_account_id(@account.account_id, options_for_klient) }
    fetch_available_tags = lambda { @available_tags = Kaui::TagDefinition.all_for_account(options_for_klient) }
    run_in_parallel fetch_overdue_state, fetch_account_tags, fetch_account_emails, fetch_payment_methods, fetch_available_tags
  end

  def trigger_invoice
    account_id = params.require(:account_id)
    target_date = params[:target_date].presence
    dry_run = params[:dry_run] == '1'

    invoice = nil
    begin
      invoice = dry_run ? Kaui::Invoice.trigger_invoice_dry_run(account_id, target_date, false, options_for_klient) :
                          Kaui::Invoice.trigger_invoice(account_id, target_date, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    rescue KillBillClient::API::NotFound
      # Null invoice
    end

    if invoice.nil?
      redirect_to account_path(account_id), :notice => "Nothing to generate for target date #{target_date.nil? ? 'today' : target_date}"
    elsif dry_run
      @invoice = Kaui::Invoice.build_from_raw_invoice(invoice)
      @payments = []
      @payment_methods = nil
      @account = Kaui::Account.find_by_id(account_id, false, false, options_for_klient)
      render :template => 'kaui/invoices/show'
    else
      # Redirect to fetch payments, etc.
      redirect_to invoice_path(invoice.invoice_id, :account_id => account_id), :notice => "Generated invoice #{invoice.invoice_number} for target date #{invoice.target_date}"
    end
  end

  # Fetched asynchronously, as it takes time. This also helps with enforcing permissions.
  def next_invoice_date
    next_invoice = Kaui::Invoice.trigger_invoice_dry_run(params.require(:account_id), nil, true, options_for_klient)
    render :json => next_invoice ? next_invoice.target_date.to_json : nil
  end

  def edit
  end

  def update
    @account = Kaui::Account.new(params.require(:account).delete_if { |key, value| value.blank? })
    @account.account_id = params.require(:account_id)

    # Transform "1" into boolean
    @account.is_migrated = @account.is_migrated == '1'
    @account.is_notified_for_invoices = @account.is_notified_for_invoices == '1'

    @account.update(true, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to account_path(@account.account_id), :notice => 'Account successfully updated'
  rescue => e
    flash.now[:error] = "Error while updating account: #{as_string(e)}"
    render :action => :edit
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
