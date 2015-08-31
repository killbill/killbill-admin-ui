class Kaui::CreditsController < Kaui::EngineController

  def new
    invoice_id = params[:invoice_id]
    amount = params[:amount]

    if invoice_id.present?
      @invoice = Kaui::Invoice.find_by_id_or_number(invoice_id, true, 'NONE', options_for_klient)
      amount ||= @invoice.balance
      currency = @invoice.currency
    else
      currency = params[:currency] || 'USD'
    end

    @credit = Kaui::Credit.new(:account_id => params.require(:account_id), :invoice_id => invoice_id, :credit_amount => amount, :currency => currency)
  end

  def create
    credit = Kaui::Credit.new(params[:credit].delete_if { |key, value| value.blank? })
    credit.account_id ||= params.require(:account_id)

    credit = credit.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
    redirect_to kaui_engine.account_path(credit.account_id), :notice => 'Credit was successfully created'
  end
end
