class Kaui::PaymentsController < Kaui::EngineController

  def index
    @search_query = params[:q] || params[:account_id]

    @ordering = params[:ordering] || (@search_query.blank? ? 'desc' : 'asc')
    @offset = params[:offset] || 0
    @limit = params[:limit] || 50

    @max_nb_records = @search_query.blank? ? Kaui::Payment.list_or_search(nil, 0, 0, options_for_klient).pagination_max_nb_records : 0
  end

  def pagination
    searcher = lambda do |search_key, offset, limit|
      if Kaui::Payment::TRANSACTION_STATUSES.include?(search_key)
        # Search is done by payment state on the server side, see http://docs.killbill.io/latest/userguide_payment.html#_payment_states
        payment_state = if %w(PLUGIN_FAILURE UNKNOWN).include?(search_key)
                          '_ERRORED'
                        elsif search_key == 'PAYMENT_FAILURE'
                          '_FAILED'
                        else
                          '_' + search_key
                        end
        payments = Kaui::Payment.list_or_search(payment_state, offset, limit, options_for_klient)
      else
        account = Kaui::Account::find_by_id_or_key(search_key, false, false, options_for_klient) rescue nil
        if account.nil?
          payments = Kaui::Payment.list_or_search(search_key, offset, limit, options_for_klient)
        else
          payments = account.payments(options_for_klient).map! { |payment| Kaui::Payment.build_from_raw_payment(payment) }
        end
      end

      payments.each do |payment|
        created_date = nil
        payment.transactions.each do |transaction|
          transaction_date = DateTime.parse(transaction.effective_date)
          if created_date.nil? or transaction_date < created_date
            created_date = transaction_date
          end
        end
        payment.payment_date = created_date
      end

      payments
    end

    data_extractor = lambda do |payment, column|
      [
          payment.payment_number.to_i,
          payment.payment_date,
          payment.total_authed_amount_to_money,
          payment.paid_amount_to_money,
          payment.returned_amount_to_money,
          payment.transactions.empty? ? nil : payment.transactions[-1].status
      ][column]
    end

    formatter = lambda do |payment|
      [
          view_context.link_to(payment.payment_number, view_context.url_for(:controller => :payments, :action => :show, :account_id => payment.account_id, :id => payment.payment_id)),
          view_context.format_date(payment.payment_date),
          view_context.humanized_money_with_symbol(payment.total_authed_amount_to_money),
          view_context.humanized_money_with_symbol(payment.paid_amount_to_money),
          view_context.humanized_money_with_symbol(payment.returned_amount_to_money),
          payment.transactions.empty? ? nil : view_context.colored_transaction_status(payment.transactions[-1].status)
      ]
    end

    paginate searcher, data_extractor, formatter
  end

  def new
    fetch_invoice = lambda { @invoice = Kaui::Invoice.find_by_id_or_number(params.require(:invoice_id), true, 'NONE', options_for_klient) }
    fetch_account = lambda { @account = Kaui::Account.find_by_id(params.require(:account_id), false, false, options_for_klient) }
    fetch_payment_methods = lambda { @payment_methods = Kaui::PaymentMethod.find_all_by_account_id(params.require(:account_id), false, options_for_klient) }

    run_in_parallel fetch_invoice, fetch_account, fetch_payment_methods

    @payment = Kaui::InvoicePayment.new('accountId' => @account.account_id, 'targetInvoiceId' => @invoice.invoice_id, 'purchasedAmount' => @invoice.balance)
  end

  def create
    payment = Kaui::InvoicePayment.new(invoice_payment_params)
    payment = payment.create(params[:external] == '1', current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_invoice_path(payment.account_id, payment.target_invoice_id), :notice => 'Payment created'
  end

  def show
    invoice_payment = Kaui::InvoicePayment.find_safely_by_id(params.require(:id), options_for_klient)
    @payment = Kaui::InvoicePayment.build_from_raw_payment(invoice_payment)

    fetch_account = lambda { @account = Kaui::Account.find_by_id(@payment.account_id, false, false, options_for_klient) }
    # The payment method may have been deleted
    fetch_payment_method = lambda { @payment_method = Kaui::PaymentMethod.find_safely_by_id(@payment.payment_method_id, options_for_klient) }

    run_in_parallel fetch_account, fetch_payment_method
  end

  def restful_show
    begin
      payment = Kaui::InvoicePayment.find_by_id(params.require(:id), false, true, options_for_klient)
    rescue KillBillClient::API::NotFound
      payment = Kaui::Payment.find_by_external_key(params.require(:id), false, true, options_for_klient)
    end
    redirect_to account_payment_path(payment.account_id, payment.payment_id)
  end

  def cancel_scheduled_payment
    begin
      payment_transaction = Kaui::Transaction.new
      payment_transaction.transaction_external_key = params.require(:transaction_external_key)

      payment_transaction.cancel_scheduled_payment(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_payment_path(params.require(:account_id), params.require(:id)), :notice => "Payment attempt retry successfully deleted"
    rescue => e
      flash[:error] = "Error deleting payment attempt retry: #{as_string(e)}"
      redirect_to kaui_engine.account_path(params.require(:account_id))
    end
  end

  private

  def invoice_payment_params
    invoice_payment = params.require(:invoice_payment)
    invoice_payment.require(:target_invoice_id)
    invoice_payment
  end
end
