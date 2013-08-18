class Kaui::ChargesController < Kaui::EngineController

  def new
    @account_id = params[:account_id]
    @invoice_id = params[:invoice_id]
    begin
      @account = Kaui::KillbillHelper::get_account(@account_id, options_for_klient)

      if @invoice_id.present?
        @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id, options_for_klient)
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
        Kaui::KillbillHelper::create_charge(charge, params[:requested_date], current_user, nil, params[:comment], options_for_klient)
        flash[:notice] = "Charge created"
        redirect_to kaui_engine.account_timeline_path(:id => charge.account_id)
      rescue => e
        flash.now[:error] = "Error while creating a charge: #{as_string(e)}"
      end
    end
  end

end
