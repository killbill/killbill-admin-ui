class Kaui::AccountsController < Kaui::EngineController

  def index
    @search_query = params[:q]
  end

  def pagination
    search_key = params[:sSearch]
    offset = params[:iDisplayStart] || 0
    limit = params[:iDisplayLength] || 10

    accounts = Kaui::Account.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho => params[:sEcho],
        :iTotalRecords => accounts.pagination_max_nb_records,
        :iTotalDisplayRecords => accounts.pagination_total_nb_records,
        :aaData => []
    }

    accounts.each do |account|
      json[:aaData] << [
          view_context.link_to(account.name, view_context.url_for(:action => :show, :account_id => account.account_id)),
          view_context.truncate_uuid(account.account_id),
          account.external_key,
          view_context.humanized_money_with_symbol(account.balance_to_money),
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
    @overdue_state = @account.overdue(options_for_klient)
    @tags = @account.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }

    @account_emails = Kaui::AccountEmail.find_all_sorted_by_account_id(@account.account_id, 'NONE', options_for_klient)
    @payment_methods = Kaui::PaymentMethod.find_non_external_by_account_id(@account.account_id, true, options_for_klient)
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
