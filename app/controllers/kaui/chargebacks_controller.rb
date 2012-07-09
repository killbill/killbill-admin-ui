class Kaui::ChargebacksController < ApplicationController
  def show
    @payment_id = params[:id]
    if @payment_id.present?
      data = Kaui::KillbillHelper::get_chargebacks_for_payment(@payment_id)
      if data.present?
        @chargeback = Kaui::Chargeback.new(data)
      else
        Rails.logger.warn("Did not get back chargebacks #{response_body}")
      end
    else
      flash[:notice] = "No id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @chargeback = Kaui::Chargeback.new(:payment_id => @payment_id, 
                                       :invoice_id => @invoice_id,
                                       :account_id => @account_id)

    # @payment_attempt = Kaui::KillbillHelper::get_payment_attempt(@external_key, @invoice_id, @payment_id)
    @account = Kaui::KillbillHelper::get_account(@account_id)
    # TODO: get payment by payment id (no api at the moment)
    @payment = Kaui::KillbillHelper::get_payment(@invoice_id, @payment_id)
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
  end

  def create
    chargeback = Kaui::Chargeback.new(params[:chargeback])
    # TODO: read chargeback object from post params
    #Kaui::KillbillHelper::create_chargeback(@payment_id)
    redirect_to account_timeline_path(:id => chargeback.account_id)
  end
end
