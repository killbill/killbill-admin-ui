class Kaui::PaymentsController < Kaui::EngineController

  def new
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @payment = Kaui::Payment.new("invoiceId" => @invoice_id)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
  end

  def create
    external_payment = Kaui::Payment.new(params[:external_payment])

    if external_payment.present?
      success = Kaui::KillbillHelper::create_external_payment(payment, current_user, params[:reason], params[:comment])
      if success
        flash[:info] = "External Payment created"
      # else
      #   flash[:error] = "Error while creating external payment"
      end
    else
      flash[:error] = "No external payment to process"
    end
    redirect_to account_timeline_path(:id => params[:account_id])
  end

end
