class Kaui::ChargesController < Kaui::EngineController

  def new
    invoice_id = params[:invoice_id]
    account_id = params[:account_id]
    currency   = params[:currency] || 'USD'

    if invoice_id.present?
      begin
        @invoice   = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)
        account_id = @invoice.account_id
        currency   = @invoice.currency
      rescue => e
        flash.now[:error] = "Unable to retrieve invoice: #{as_string(e)}"
      end
    end

    @charge = Kaui::InvoiceItem.new(:account_id => account_id, :invoice_id => invoice_id, :currency => currency)
  end

  def create
    @charge = Kaui::InvoiceItem.new(params[:invoice_item].delete_if { |key, value| value.blank? })

    begin
      @charge = @charge.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.invoice_path(:id => @charge.invoice_id), :notice => 'Charge was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating a charge: #{as_string(e)}"
      render :action => :new
    end
  end
end
