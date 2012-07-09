class Kaui::RefundsController < ApplicationController
	def show
    @payment_id = params[:id]
    if @payment_id.present?
      data = Kaui::KillbillHelper::get_refunds_for_payment(@payment_id)
      if data.present?
        @refund = Kaui::Refund.new(data)
      else
        Rails.logger.warn("Did not get back refunds for the payment id #{response_body}")
      end
    else
      flash[:notice] = "No payment id given"
    end
  end

  def new
    @payment_id = params[:payment_id]
    @invoice_id = params[:invoice_id]
    @account_id = params[:account_id]

    @refund = Kaui::Refund.new(:payment_id => @payment_id, 
                               :invoice_id => @invoice_id,
                               :account_id => @account_id)

    @account = Kaui::KillbillHelper::get_account(@account_id)
    # @payment_attempt = Kaui::KillbillHelper::get_payment_attempt(@external_key, @invoice_id, @payment_id)
    @payment = Kaui::KillbillHelper::get_payment(@invoice_id, @payment_id)
    puts "payment is #{@payment.to_yaml}"
    @invoice = Kaui::KillbillHelper::get_invoice(@invoice_id)
  end

  def create
    refund = Kaui::Refund.new(params[:refund])
    # TODO: read refund object from post params
    #Kaui::KillbillHelper::create_refund(refund)
    redirect_to account_timeline_path(:id => refund.account_id)
  end
end
