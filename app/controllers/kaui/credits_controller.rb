class Kaui::CreditsController < Kaui::EngineController
  def show
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    if params.has_key?(:account_id)
      begin
      # invoice id can be nil for account level credit
        data = Kaui::KillbillHelper::get_credits(@account_id, @invoice_id)
      rescue => e
        flash[:error] = "Error getting credit information: #{e.message} #{e.response}"
      end
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

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id) unless @invoice_id.nil?
    rescue => e
      flash[:error] = "Error while starting to create credit: #{e.message} #{e.response}"
    end

    credit_amount = @invoice.balance unless @invoice.nil?

    @credit = Kaui::Credit.new("accountId" => @account_id, "invoiceId" => @invoice_id,
                               "creditAmount" => credit_amount, "effectiveDate" => Time.now.utc.iso8601)
  end

  def create
    credit = Kaui::Credit.new(params[:credit])
    begin
      Kaui::KillbillHelper::create_credit(credit, current_user, params[:reason], params[:comment])
      account = Kaui::KillbillHelper::get_account(credit.account_id)
      flash[:info] = "Credit created"
    rescue => e
      flash[:error] = "Error while starting to create credit: #{e.message} #{e.response}"
    end
    redirect_to Kaui.account_home_path.call(account.external_key)
  end
end
