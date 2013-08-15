class Kaui::ChargebacksController < Kaui::EngineController

  def show
    @payment_id = params[:id]
    if @payment_id.present?
      begin
        data = Kaui::KillbillHelper::get_chargebacks_for_payment(@payment_id)
      rescue => e
        flash.now[:error] = "Error while getting chargeback information: #{as_string(e)}"
      end
      if data.present?
        @chargeback = Kaui::Chargeback.new(data)
      else
        Rails.logger.warn("Did not get back chargebacks #{response_body}")
      end
    else
      flash.now[:notice] = "No id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id)
      @payment = Kaui::KillbillHelper::get_payment(@payment_id)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
    rescue => e
      flash[:error] = "Error while starting a new chargeback: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
    end

    # The payment method may have been deleted
    @payment_method = Kaui::KillbillHelper::get_payment_method(@payment.payment_method_id) rescue nil

    @chargeback = Kaui::Chargeback.new("paymentId" => @payment_id,
                                       "chargebackAmount" => @payment.amount)
  end

  def create
    account_id = params[:account_id]
    chargeback = Kaui::Chargeback.new(params[:chargeback])

    if chargeback.present?
      begin
        Kaui::KillbillHelper::create_chargeback(chargeback, params[:reason], params[:comment])
        flash[:notice] = "Chargeback created"
      rescue => e
        flash[:error] = "Error while creating a new chargeback: #{as_string(e)}"
      end
    else
      flash[:error] = "No chargeback to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end
end
