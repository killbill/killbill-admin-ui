class Kaui::RefundsController < Kaui::EngineController
  def index
    if params[:refund_id].present?
      redirect_to refund_path(params[:refund_id])
    end
  end

  def show
    if params[:id].present?
      data = Kaui::KillbillHelper::get_refund(params[:id])
      if data.present?
        @refunds = [data]
      else
        @refunds = Kaui::KillbillHelper::get_refunds_for_payment(params[:id])
        unless @refunds.present?
          flash[:error] = "Refund for id or payment id #{params[:id]} couldn't be found"
          render :action => :index
        end
      end
    else
      flash[:error] = "A refund or payment id should be specifed"
      render :action => :index
    end
  end

  def new
    @payment_id = params[:payment_id]
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @refund = Kaui::Refund.new('adjusted' => true)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @payment = Kaui::KillbillHelper::get_payment(@payment_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
    @payment_method = Kaui::KillbillHelper::get_payment_method(@payment.payment_method_id)
  end

  def create
    payment_id = params[:payment_id]
    account_id = params[:account_id]

    refund = Kaui::Refund.new(params[:refund])
    refund.adjusted = (refund.adjusted == "1")
    if refund.present?
      success = Kaui::KillbillHelper::create_refund(params[:payment_id], refund, current_user, params[:reason], params[:comment])
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
