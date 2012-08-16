class Kaui::PaymentsController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
    @account = Kaui::KillbillHelper::get_account(@account_id)

    @payment = Kaui::Payment.new("accountId" => @account_id, "invoiceId" => @invoice_id, "amount" => @invoice.balance)
  end

  def create
    payment = Kaui::Payment.new(params[:payment])

    if payment.present?
      success = Kaui::KillbillHelper::create_payment(payment, params[:external], current_user, params[:reason], params[:comment])
      if success
        flash[:info] = "Payment created"
      end
    else
      flash[:error] = "No payment to process"
    end
    redirect_to account_timeline_path(:id => payment.account_id)
  end

end
