class Kaui::ExternalPaymentsController < Kaui::EngineController
  def new
    invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @external_payment = Kaui::ExternalPayment.new("invoiceId" => invoice_id, "accountId" => @account_id)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @invoice = Kaui::KillbillHelper::get_invoice(invoice_id)
  end

  def create
    external_payment = Kaui::ExternalPayment.new(params[:external_payment])

    success = Kaui::KillbillHelper::create_external_payment(external_payment, current_user, params[:reason], params[:comment])
    if success
      flash[:info] = "External Payment created"
    # else
    #   flash[:error] = "Error while creating external payment"
    end
    redirect_to account_timeline_path(external_payment.account_id)
  end
end