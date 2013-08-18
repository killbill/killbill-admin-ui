class Kaui::InvoiceItemsController < Kaui::EngineController
  def index
    if params[:invoice_item_id].present? and params[:invoice_id].present?
      redirect_to kaui_engine.invoice_item_path(params[:invoice_item_id], :invoice_id => params[:invoice_id])
    end
  end

  def show
    find_invoice_item
  end

  def edit
    find_invoice_item
  end

  def update
    @invoice_item = Kaui::InvoiceItem.new(params[:invoice_item])
    begin
      Kaui::KillbillHelper.adjust_invoice(@invoice_item, current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = "Adjustment item created"
      redirect_to kaui_engine.invoice_path(@invoice_item.invoice_id)
    rescue => e
      flash.now[:error] = "Error while updating the invoice item: #{as_string(e)}"
      render :action => "edit"
    end
  end

  def destroy
    begin
      Kaui::KillbillHelper.delete_cba(params[:account_id], params[:invoice_id], params[:id], current_user, params[:reason], params[:comment], options_for_klient)
      flash[:notice] = "CBA deleted"
      redirect_to kaui_engine.invoice_path(params[:invoice_id])
    rescue => e
      flash[:error] = "Error while deleting the CBA: #{as_string(e)}"
      redirect_to kaui_engine.invoice_path(params[:invoice_id])
    end
  end

  private

  def find_invoice_item
    invoice_item_id = params[:id]
    invoice_id = params[:invoice_id]
    if invoice_item_id.present? and invoice_id.present?
      begin
        @invoice_item = Kaui::KillbillHelper.get_invoice_item(invoice_id, invoice_item_id, options_for_klient)
      rescue => e
        flash[:error] = "Error while trying to find the invoice item: #{as_string(e)}"
      end
      unless @invoice_item.present?
        flash[:error] = "Invoice for id #{invoice_id} and invoice item id #{invoice_item_id} not found"
        render :action => :index
      end
    else
      flash[:error] = "Both invoice item and invoice ids should be specified"
      render :action => :index
    end
  end
end
