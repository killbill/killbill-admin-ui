class Kaui::RefundsController < Kaui::EngineController
  def index
    if params[:refund_id].present?
      redirect_to kaui_engine.refund_path(params[:refund_id])
    end
  end

  def show
    if params[:id].present?
      begin
        data = Kaui::KillbillHelper::get_refund(params[:id], options_for_klient)
      rescue => e
        flash.now[:error] = "Error while retrieving the refund with id #{params[:id]}: #{as_string(e)}"
      end
      if data.present?
        @refunds = [data]
      else
        begin
          @refunds = Kaui::KillbillHelper::get_refunds_for_payment(params[:id], options_for_klient)
          unless @refunds.present?
            flash.now[:error] = "Refund for id or payment id #{params[:id]} couldn't be found"
            render :action => :index and return
          end
        rescue => e
          flash.now[:error] = "Error while retrieving the refunds for the payment: #{as_string(e)}"
          render :action => :index and return
        end
      end

      if @refunds.size > 0
        begin
          # Retrieve the account via the payment
          payment = Kaui::KillbillHelper::get_payment(@refunds[0].payment_id, options_for_klient)
          unless payment.present?
            flash.now[:error] = "Account for payment id #{@refunds[0].payment_id} couldn't be found"
            render :action => :index
          end
          @account = Kaui::KillbillHelper::get_account(payment.account_id, options_for_klient)
        rescue => e
          flash.now[:error] = "Error while retrieving the account for the refund: #{as_string(e)}"
          render :action => :index
        end
      end
    else
      flash.now[:error] = "A refund or payment id should be specifed"
      render :action => :index
    end
  end

  def new
    @payment_id = params[:payment_id]
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @refund = Kaui::Refund.new('adjusted' => true)

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id, options_for_klient)
      @payment = Kaui::KillbillHelper::get_payment(@payment_id, options_for_klient)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, options_for_klient)
    rescue => e
      flash[:error] = "Error while processing refund: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
    end
  end

  def create
    invoice = Kaui::KillbillHelper::get_invoice(params[:invoice_id], options_for_klient)
    refund = Kaui::Refund.new(params[:refund])
    refund.adjusted = (refund.adjustment_type != "noInvoiceAdjustment")
    if refund.adjustment_type == "invoiceItemAdjustment"
      refund.adjustments = []
      params[:adjustments].each_with_index do |ii, idx|
        original_item = find_original_item(invoice.items, ii[0])
        h = Hash.new
        h[:invoice_item_id] = ii[0]
        # If we tried to do a partial item adjustment, we pass the value, if not we don't send any value and let the system
        # decide what is the maxium amount we can have on that item
        h[:amount] = (ii[1].to_f == original_item.amount) ? nil : ii[1]
        kaui_ii = Kaui::InvoiceItem.new(h)
        puts "Got #{kaui_ii.inspect}"
        refund.adjustments[idx] = kaui_ii
      end
    end
    if refund.present?
      begin
        Kaui::KillbillHelper::create_refund(params[:payment_id], refund, current_user, params[:reason], params[:comment], options_for_klient)
        flash[:notice] = "Refund created"
      rescue => e
        flash[:error] = "Error while processing refund: #{as_string(e)}"
      end
    else
      flash[:error] = "No refund to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => params[:account_id])
  end

  private

  def find_original_item(items, item_id)
    items.each do |ii|
      if ii.invoice_item_id == item_id
        return ii
      end
    end
    nil
  end

end
