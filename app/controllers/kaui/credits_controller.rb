class Kaui::CreditsController < Kaui::EngineController

  def new
    invoice_id = params[:invoice_id]
    amount = params[:amount]

    if invoice_id.present?
      @invoice = Kaui::Invoice.find_by_id(invoice_id, true, 'NONE', options_for_klient)
      amount ||= @invoice.balance
      currency = @invoice.currency
    else
      @invoice = nil
      currency = params[:currency] || 'USD'
    end

    @credit = Kaui::Credit.new(:account_id => params.require(:account_id), :invoice_id => invoice_id, :credit_amount => amount, :currency => currency)
  end

  def create
    credit = Kaui::Credit.new(params[:credit].delete_if { |key, value| value.blank? })
    credit.account_id ||= params.require(:account_id)

    # No need to show the newly created invoice for account level credits
    should_redirect_to_invoice = credit.invoice_id.present?

    credit = credit.create(true, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    flash[:notice] = 'Credit was successfully created'

    if should_redirect_to_invoice
      redirect_to kaui_engine.account_invoice_path(credit.account_id, credit.invoice_id)
    else
      redirect_to kaui_engine.account_path(credit.account_id)
    end
  end
end
