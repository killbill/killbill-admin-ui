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
    credit_amount = @invoice.balance unless @invoice.nil?

    @credit = Kaui::Credit.new("accountId" => @account_id, "invoiceId" => @invoice_id,
                               "creditAmount" => credit_amount, "effectiveDate" => Time.now.utc.iso8601)
  end

  def create
    credit = Kaui::Credit.new(params[:credit])
    success = Kaui::KillbillHelper::create_credit(credit, current_user, params[:reason], params[:comment])
    if success
      flash[:info] = "Credit created"
    else
      flash[:error] = "Error while creating credit"
    end
    account = Kaui::KillbillHelper::get_account(credit.account_id)
    redirect_to Kaui.account_home_path.call(account.external_key)
  end
end
