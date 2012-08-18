class Kaui::CreditsController < Kaui::EngineController
  def show
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    if params.has_key?(:account_id)
    # invoice id can be nil for account level credit
      data = Kaui::KillbillHelper::get_credits(@account_id, @invoice_id)
      if data.present?
        @credit = Kaui::Credit.new(data)
      else
        Rails.logger.warn("Did not get back external payments #{response_body}")
      end
    else
      flash[:notice] = "No id given"
    end
  end

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    @account = Kaui::KillbillHelper::get_account(@account_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id) unless @invoice_id.nil?

    @credit = Kaui::Credit.new("accountId" => @account_id, "invoiceId" => @invoice_id, "creditAmount" => @invoice.balance)
  end

  def create
    credit = Kaui::Credit.new(params[:credit])
    success = Kaui::KillbillHelper::create_credit(credit, current_user, params[:reason], params[:comment])
    if success
      flash[:info] = "Credit created"
    else
      flash[:error] = "Error while creating credit"
    end
    redirect_to kaui_engine.account_timeline_path(credit.account_id)
  end
end
