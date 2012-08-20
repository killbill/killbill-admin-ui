class Kaui::ChargesController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]

    @account = Kaui::KillbillHelper::get_account(@account_id)

    if @invoice_id.present?
      @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
      @charge = Kaui::Charge.new("accountId" => @account_id, "invoiceId" => @invoice_id)
    else
      @charge = Kaui::Charge.new("accountId" => @account_id)
    end

  end

  def create
    charge = Kaui::Charge.new(params[:charge])

    if charge.present?
      success = Kaui::KillbillHelper::create_charge(charge, params[:requested_date], current_user, nil, params[:comment])
      if success
        flash[:info] = "Charge created"
      end
    else
      flash[:error] = "No charge to process"
    end
    redirect_to kaui_engine.account_timeline_path(:id => charge.account_id)
  end

end
