class Kaui::InvoiceItemsController < Kaui::EngineController

  def edit
    invoice_item_id = params.require(:id)
    invoice_id = params.require(:invoice_id)

    invoice = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)

    @invoice_item = invoice.items.find { |ii| ii.invoice_item_id == invoice_item_id }
    raise "Unable to find invoice item #{invoice_item_id}" if @invoice_item.nil?
  end

  def update
    @invoice_item = Kaui::InvoiceItem.new(params.require(:invoice_item))

    begin
      invoice = @invoice_item.update(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_invoice_path(invoice.account_id, invoice.invoice_id), :notice => 'Adjustment item was successfully created'
    rescue => e
      flash.now[:error] = "Error while adjusting invoice item: #{as_string(e)}"
      render :action => :edit
    end
  end

  def destroy
    @invoice_item = Kaui::InvoiceItem.new(:invoice_item_id => params.require(:id),
                                          :invoice_id => params.require(:invoice_id),
                                          :account_id => params.require(:account_id))

    begin
      @invoice_item.delete(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_invoice_path(@invoice_item.account_id, @invoice_item.invoice_id), :notice => 'CBA item was successfully deleted'
    rescue => e
      flash.now[:error] = "Error while deleting CBA item: #{as_string(e)}"
      render :action => :edit
    end
  end
end
