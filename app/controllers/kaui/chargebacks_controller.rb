class Kaui::ChargebacksController < Kaui::EngineController

  def show
    @payment_id = params[:id]
    if @payment_id.present?
      data = Kaui::KillbillHelper::get_chargebacks_for_payment(@payment_id)
      if data.present?
        @chargeback = Kaui::Chargeback.new(data)
      else
        Rails.logger.warn("Did not get back chargebacks #{response_body}")
      end
    else
      flash[:notice] = "No id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    # @payment_attempt = Kaui::KillbillHelper::get_payment_attempt(@external_key, @invoice_id, @payment_id)
    @account = Kaui::KillbillHelper::get_account(@account_id)
    @payment = Kaui::KillbillHelper::get_payment(@payment_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
    @payment_method = Kaui::KillbillHelper::get_payment_method(@payment.payment_method_id)

    @chargeback = Kaui::Chargeback.new("payment_id" => @payment_id,
                                       "chargeback_amount" => @payment.amount)
  end

  def create
    account_id = params[:account_id]
    chargeback = Kaui::Chargeback.new(params[:chargeback])
    if chargeback.present?
      success = Kaui::KillbillHelper::create_chargeback(chargeback, params[:reason], params[:comment])
      if success
        flash[:info] = "Chargeback created"
      else
        flash[:error] = "Could not process chargeback"
      end
    else
      flash[:error] = "No chargeback to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end
end
