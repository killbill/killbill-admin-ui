class Kaui::RefundsController < Kaui::EngineController
  def index
    if params[:refund_id].present?
      redirect_to kaui_engine.refund_path(params[:refund_id])
    end
  end

  def show
    if params[:id].present?
      begin
        data = Kaui::KillbillHelper::get_refund(params[:id])
      rescue => e
        flash[:error] = "Error while retrieving the refund with id #{params[:id]}: #{as_string(e)}"
      end
      if data.present?
        @refunds = [data]
      else
        begin
          @refunds = Kaui::KillbillHelper::get_refunds_for_payment(params[:id])
          unless @refunds.present?
            flash[:error] = "Refund for id or payment id #{params[:id]} couldn't be found"
            render :action => :index
          end
        rescue => e
          flash[:error] = "Error while retrieving the refunds for the payment: #{as_string(e)}"
          render :action => :index
        end
      end

      if @refunds.size > 0
        begin
          # Retrieve the account via the payment
          payment = Kaui::KillbillHelper::get_payment(@refunds[0].payment_id)
          unless payment.present?
            flash[:error] = "Account for payment id #{@refunds[0].payment_id} couldn't be found"
            render :action => :index
          end
          @account = Kaui::KillbillHelper::get_account(payment.account_id)
        rescue => e
          flash[:error] = "Error while retrieving the account for the refund: #{as_string(e)}"
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

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id)
      @payment = Kaui::KillbillHelper::get_payment(@payment_id)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
    rescue => e
      flash[:error] = "Error while processing refund: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
    end
  end

  def create
    payment_id = params[:payment_id]
    account_id = params[:account_id]
    refund = Kaui::Refund.new(params[:refund])
    refund.adjusted = (refund.adjustment_type != "noInvoiceAdjustment")
    if refund.adjustment_type == "invoiceItemAdjustment"
      refund.adjustments = []
      params[:adjustments].each_with_index do |ii, idx|
        h = Hash.new
        h[:invoice_item_id] = ii[0]
        h[:amount] = ii[1]
        kaui_ii = Kaui::InvoiceItem.new(h)
        puts "Got #{kaui_ii.inspect}"
        refund.adjustments[idx] = kaui_ii
      end
    end
    if refund.present?
      begin
        Kaui::KillbillHelper::create_refund(params[:payment_id], refund, current_user, params[:reason], params[:comment])
        flash[:info] = "Refund created"
      rescue => e
        flash[:error] = "Error while processing refund: #{as_string(e)}"
      end
    else
      flash[:error] = "No refund to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end

end
