class Kaui::PaymentsController < Kaui::EngineController

  def index
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    search_key = params[:sSearch]
    if search_key.present?
      payments = Kaui::KillbillHelper::search_payments(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      payments = Kaui::KillbillHelper::get_payments(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = payments.pagination_total_nb_records
    json[:iTotalRecords] = payments.pagination_max_nb_records

    payments.each do |payment|
      json[:aaData] << [
                         view_context.link_to(payment.account_id, view_context.url_for(:controller => :accounts, :action => :show, :id => payment.account_id)),
                         payment.payment_number,
                         view_context.format_date(payment.effective_date),
                         view_context.humanized_money_with_symbol(Kaui::Base.to_money(payment.amount, payment.currency)),
                         payment.status
                       ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    begin
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, true, "NONE", options_for_klient)
      @account = Kaui::KillbillHelper::get_account(@account_id, false, false, options_for_klient)
    rescue => e
      flash[:error] = "Error while creating a new payment: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => payment.account_id)
    end

    @payment = Kaui::Payment.new("accountId" => @account_id, "invoiceId" => @invoice_id, "amount" => @invoice.balance)
  end

  def create
    payment = Kaui::Payment.new(params[:payment])
    if payment.present?
      payment.external = (payment.external == "1")
      begin
        Kaui::KillbillHelper::create_payment(payment, payment.external, current_user, params[:reason], params[:comment], options_for_klient)
        flash[:notice] = "Payment created"
      rescue => e
        flash[:error] = "Error while creating a new payment: #{as_string(e)}"
      end
    end
    redirect_to kaui_engine.account_timeline_path(:id => payment.account_id)
  end
end
