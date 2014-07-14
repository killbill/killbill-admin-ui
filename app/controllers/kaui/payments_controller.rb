class Kaui::PaymentsController < Kaui::EngineController

  def index
  end

  def pagination
    json = {:sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => []}

    search_key = params[:sSearch]
    if search_key.present?
      payments = Kaui::Payment::find_in_batches_by_search_key(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      payments = Kaui::Payment::find_in_batches(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = payments.pagination_total_nb_records
    json[:iTotalRecords]        = payments.pagination_max_nb_records

    payments.each do |payment|
      created_date = nil
      payment.transactions.each do |transaction|
        # TODO
        #transaction_date = Date.parse(transaction.effective_date)
        #if created_date.nil? or transaction_date < created_date
        #  created_date = transaction_date
        #end
      end

      json[:aaData] << [
          view_context.link_to(payment.account_id, view_context.url_for(:controller => :accounts, :action => :show, :id => payment.account_id)),
          payment.payment_number,
          view_context.format_date(created_date),
          view_context.humanized_money_with_symbol(Kaui::Base.to_money(payment.captured_amount + payment.purchased_amount, payment.currency)),
          view_context.humanized_money_with_symbol(Kaui::Base.to_money(payment.refunded_amount + payment.credited_amount, payment.currency))
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def new
    account_id = params[:account_id]
    invoice_id = params[:invoice_id]
    amount     = 0

    if invoice_id.nil?
      flash[:error] = 'No invoice id specified'
      render :action => :index and return
    end

    if account_id.nil?
      flash[:error] = 'No account id specified'
      render :action => :index and return
    end

    begin
      @invoice = Kaui::KillbillHelper::get_invoice(invoice_id, true, "NONE", options_for_klient)
      amount   = @invoice.balance
    rescue => e
      flash[:error] = "Unable to retrieve invoice: #{as_string(e)}"
      render :action => :index and return
    end

    begin
      @account = Kaui::KillbillHelper::get_account(account_id, false, false, options_for_klient)
    rescue => e
      flash[:error] = "Unable to retrieve account: #{as_string(e)}"
      render :action => :index and return
    end

    @payment = Kaui::InvoicePayment.new('accountId' => account_id, 'targetInvoiceId' => invoice_id, 'purchasedAmount' => amount)
  end

  def create
    payment          = Kaui::InvoicePayment.new(params[:invoice_payment])

    begin
      payment        = payment.create(params[:external] == '1', current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = 'Payment created'
    rescue => e
      flash[:error] = "Error while creating a new payment: #{as_string(e)}"
      render :action => :index and return
    end

    redirect_to kaui_engine.account_timeline_path(:id => payment.account_id)
  end
end
