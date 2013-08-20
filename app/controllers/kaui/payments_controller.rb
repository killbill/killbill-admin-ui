class Kaui::PaymentsController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    begin
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, true, options_for_klient)
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
