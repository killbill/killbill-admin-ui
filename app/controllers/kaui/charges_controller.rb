class Kaui::ChargesController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    begin
      @account = Kaui::KillbillHelper::get_account(@account_id)

      if @invoice_id.present?
        @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
        @charge = Kaui::Charge.new("accountId" => @account_id, "invoiceId" => @invoice_id)
      else
        @charge = Kaui::Charge.new("accountId" => @account_id)
      end
    rescue => e
      flash.now[:error] = "Error while creating a charge: #{as_string(e)}"
    end
  end

  def create
    charge = Kaui::Charge.new(params[:charge])

    if charge.present?
      begin
        Kaui::KillbillHelper::create_charge(charge, params[:requested_date], current_user, nil, params[:comment])
        flash[:notice] = "Charge created"
        redirect_to kaui_engine.account_timeline_path(:id => charge.account_id)
      rescue => e
        flash.now[:error] = "Error while creating a charge: #{as_string(e)}"
      end
    end
  end

end
