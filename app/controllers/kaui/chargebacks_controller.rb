class Kaui::ChargebacksController < Kaui::EngineController

  def show
    @payment_id = params[:id]
    if @payment_id.present?
      begin
        data = Kaui::KillbillHelper::get_chargebacks_for_payment(@payment_id)
      rescue => e
        flash[:error] = "Error while getting chargeback information: #{e.message} #{e.response}"
      end
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

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id)
      @payment = Kaui::KillbillHelper::get_payment(@payment_id)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
      @payment_method = Kaui::KillbillHelper::get_payment_method(@payment.payment_method_id)
    rescue => e
      flash[:error] = "Error while starting a new chargeback: #{e.message} #{e.response}"
      redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
    end

    @chargeback = Kaui::Chargeback.new("paymentId" => @payment_id,
                                       "chargebackAmount" => @payment.amount)
  end

  def create
    account_id = params[:account_id]
    chargeback = Kaui::Chargeback.new(params[:chargeback])

    if chargeback.present?
      begin
        Kaui::KillbillHelper::create_chargeback(chargeback, params[:reason], params[:comment])
        flash[:info] = "Chargeback created"
      rescue => e
        flash[:error] = "Error while creating a new chargeback: #{e.message} #{e.response}"
      end
    else
      flash[:error] = "No chargeback to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end
end
