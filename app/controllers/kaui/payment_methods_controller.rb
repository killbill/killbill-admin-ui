require 'kaui/killbill_helper'

class Kaui::PaymentMethodsController < Kaui::EngineController
  def index
    if params[:key]
      params[:key].strip!
      begin
        @payment_methods = Kaui::KillbillHelper.get_payment_methods(params[:key], options_for_klient)
        render :show
      rescue => e
        flash.now[:error] = "Error while retrieving payment method for account: #{params[:key]}: #{as_string(e)}"
      end
    end
  end

  def show
    @payment_methods = []
    begin
      @payment_methods << Kaui::KillbillHelper.get_payment_method(params[:id], options_for_klient)
    rescue => e
      flash.now[:error] = "Error while retrieving payment method #{params[:id]}: #{as_string(e)}"
    end
  end

  def destroy
    payment_method_id = params[:id]
    if payment_method_id.present?
      begin
        Kaui::KillbillHelper.delete_payment_method(payment_method_id, params[:set_auto_pay_off], current_user, params[:reason], params[:comment], options_for_klient)
      rescue => e
        flash[:error] = "Error while deleting payment method #{payment_method_id}: #{as_string(e)}"
      end
    else
      flash[:notice] = 'Did not get the payment method id'
    end
    redirect_to :back
  end
end
