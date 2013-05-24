require 'kaui/killbill_helper'

class Kaui::PaymentMethodsController < Kaui::EngineController
  def show
    @payment_method = Kaui::KillbillHelper.get_payment_method params[:id]
  end

  def destroy
    payment_method_id = params[:id]
    if payment_method_id.present?
      begin
        Kaui::KillbillHelper.delete_payment_method(payment_method_id, params[:set_auto_pay_off], current_user, params[:reason], params[:comment])
      rescue => e
        flash[:error] = "Error while deleting payment method #{payment_method_id}: #{as_string(e)}"
      end
    else
      flash[:notice] = "Did not get the payment method id"
    end
    redirect_to :back
  end
end
