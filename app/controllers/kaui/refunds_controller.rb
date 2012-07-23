class Kaui::RefundsController < Kaui::EngineController
	def show
    @payment_id = params[:id]
    if @payment_id.present?
      data = Kaui::KillbillHelper::get_refunds_for_payment(@payment_id)
      if data.present?
        @refund = Kaui::Refund.new(data)
      else
        Rails.logger.warn("Did not get back refunds for the payment id #{response_body}")
      end
    else
      flash[:notice] = "No payment id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @refund = Kaui::Refund.new('adjusted' => true)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @payment = Kaui::KillbillHelper::get_payment(@invoice_id, @payment_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
  end

  def create
    payment_id = params[:payment_id]
    account_id = params[:account_id]

    refund = Kaui::Refund.new(params[:refund])
    refund.adjusted = (refund.adjusted == "1")
    if refund.present?
      success = Kaui::KillbillHelper::create_refund(params[:payment_id], refund, params[:reason], params[:comment])
      if success
        flash[:info] = "Refund created"
      else
        flash[:error] = "Error while processing refund"
      end
    else
      flash[:error] = "No refund to process"
    end
    redirect_to account_timeline_path(:id => params[:account_id])
  end

end
