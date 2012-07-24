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

    @credit = Kaui::Credit.new(:invoice_id => @invoice_id,
                               :account_id => @account_id)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
  end

  def create
    credit = Kaui::Credit.new(params[:credit])
    # TODO: read credit object from post params
    #Kaui::KillbillHelper::create_credit(@payment_id)
    redirect_to account_timeline_path(:id => credit.account_id)
  end
end
