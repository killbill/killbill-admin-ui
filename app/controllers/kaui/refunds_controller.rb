class Kaui::RefundsController < Kaui::EngineController

  def new
    payment_id = params[:payment_id]
    invoice_id = params[:invoice_id]
    account_id = params[:account_id]

    @refund = KillBillClient::Model::InvoiceItem.new

    begin
      @account = Kaui::Account.find_by_id(account_id, false, false, options_for_klient)
      @payment = Kaui::InvoicePayment::find_by_id(payment_id, false, options_for_klient)
      @invoice = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)
    rescue => e
      flash[:error] = "Error while processing refund: #{as_string(e)}"
      redirect_to kaui_engine.account_timeline_path(:id => account_id)
    end
  end

  def create
    invoice = Kaui::Invoice.find_by_id_or_number(params[:invoice_id], true, 'NONE', options_for_klient)

    items = []
    if params[:adjustment_type] == 'invoiceItemAdjustment'
      (params[:adjustments] || []).each do |ii|
        original_item       = find_original_item(invoice.items, ii[0])

        item = KillBillClient::Model::InvoiceItem.new
        item.invoice_item_id = ii[0]
        # If we tried to do a partial item adjustment, we pass the value, if not we don't send any value and let the system
        # decide what is the maximum amount we can have on that item
        item.amount = (ii[1].to_f == original_item.amount) ? nil : ii[1]

        items << item
      end
    end

    begin
      KillBillClient::Model::InvoicePayment.refund(params[:payment_id], params[:amount], items, current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = 'Refund created'
    rescue => e
      flash[:error] = "Error while processing refund: #{as_string(e)}"
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
