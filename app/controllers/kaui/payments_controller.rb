class Kaui::PaymentsController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    begin
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
      @account = Kaui::KillbillHelper::get_account(@account_id)
    rescue => e
      flash[:error] = "Error while creating a new payment: #{e.message} #{e.response}"
      redirect_to kaui_engine.account_timeline_path(:id => payment.account_id)
    end

    @payment = Kaui::Payment.new("accountId" => @account_id, "invoiceId" => @invoice_id, "amount" => @invoice.balance)
  end

  def create
    payment = Kaui::Payment.new(params[:payment])

    if payment.present?
      begin
        Kaui::KillbillHelper::create_payment(payment, params[:external], current_user, params[:reason], params[:comment])
        flash[:info] = "Payment created"
      rescue => e
        flash[:error] = "Error while creating a new payment: #{e.message} #{e.response}"
      end
    end
    redirect_to kaui_engine.account_timeline_path(:id => payment.account_id)
  end

end
