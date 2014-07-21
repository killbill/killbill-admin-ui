class Kaui::CreditsController < Kaui::EngineController

  def new
    invoice_id = params[:invoice_id]
    account_id = params[:account_id]
    amount     = params[:amount]
    currency   = params[:currency] || 'USD'

    if invoice_id.present?
      begin
        @invoice   = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)
        account_id = @invoice.account_id
        amount     ||= @invoice.balance
        currency   = @invoice.currency
      rescue => e
        flash.now[:error] = "Unable to retrieve invoice: #{as_string(e)}"
      end
    end

    # TODO Specifying a custom currency is not supported yet
    @credit = Kaui::Credit.new(:invoice_id    => invoice_id,
                               :account_id    => account_id,
                               :credit_amount => amount)
  end

  def create
    @credit = Kaui::Credit.new(params[:credit].delete_if { |key, value| value.blank? })

    begin
      @credit = @credit.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.invoice_path(:id => @credit.invoice_id), :notice => 'Credit was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating a credit: #{as_string(e)}"
      render :action => :new
    end
  end
end
