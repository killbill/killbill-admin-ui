class Kaui::RefundsController < Kaui::EngineController

  def new
    fetch_invoice = lambda { @invoice = Kaui::Invoice.find_by_id_or_number(params.require(:invoice_id), true, 'NONE', options_for_klient) }
    fetch_payment = lambda { @payment = Kaui::InvoicePayment::find_by_id(params.require(:payment_id), false, options_for_klient) }

    run_in_parallel fetch_invoice, fetch_payment

    @refund = KillBillClient::Model::InvoiceItem.new(:invoice_id => @invoice.invoice_id)
  end

  def create
    invoice = Kaui::Invoice.find_by_id_or_number(params.require(:invoice_id), true, 'NONE', options_for_klient)

    if params[:adjustment_type] == 'invoiceItemAdjustment'
      items = []
      (params[:adjustments] || []).each do |ii|
        original_item = find_original_item(invoice.items, ii[0])

        item = KillBillClient::Model::InvoiceItem.new
        item.invoice_item_id = ii[0]
        # If we tried to do a partial item adjustment, we pass the value, if not we don't send any value and let the system
        # decide what is the maximum amount we can have on that item
        item.amount = (ii[1].to_f == original_item.amount) ? nil : ii[1]

        items << item
      end
    end

    KillBillClient::Model::InvoicePayment.refund(params.require(:payment_id), params[:amount], items, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_invoice_path(invoice.account_id, invoice.invoice_id), :notice => 'Refund created'
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
