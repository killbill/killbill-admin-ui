class Kaui::CreditsController < Kaui::EngineController
  def show
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    if params.has_key?(:account_id)
      begin
      # invoice id can be nil for account level credit
        data = Kaui::KillbillHelper::get_credits(@account_id, @invoice_id, options_for_klient)
      rescue => e
        flash.now[:error] = "Error getting credit information: #{as_string(e)}"
      end
      if data.present?
        @credit = Kaui::Credit.new(data)
      else
        Rails.logger.warn("Did not get back external payments #{response_body}")
      end
    else
      flash.now[:notice] = "No id given"
    end
  end

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    begin
      @account = Kaui::KillbillHelper::get_account(@account_id, false, false, options_for_klient)
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, true, options_for_klient) unless @invoice_id.nil?
    rescue => e
      flash.now[:error] = "Error while starting to create credit: #{as_string(e)}"
    end

    credit_amount = @invoice.balance unless @invoice.nil?

    @credit = Kaui::Credit.new("accountId" => @account_id, "invoiceId" => @invoice_id,
                               "creditAmount" => credit_amount, "effectiveDate" => Date.parse(Time.now.to_s).to_s)
  end

  def create
    credit = Kaui::Credit.new(params[:credit])
    begin
      Kaui::KillbillHelper::create_credit(credit, current_user, params[:reason], params[:comment], options_for_klient)
      account = Kaui::KillbillHelper::get_account(credit.account_id, false, false, options_for_klient)
      flash[:notice] = "Credit created"
    rescue => e
      flash[:error] = "Error while starting to create credit: #{as_string(e)}"
    end
    redirect_to Kaui.account_home_path.call(credit.account_id)
  end
end
