require 'kaui/killbill_helper'

class Kaui::PaymentMethodsController < Kaui::EngineController
  def show
    # TODO: show payment method details
  end

  def destroy
    payment_method_id = params[:id]
    if payment_method_id.present?
      begin
        Kaui::KillbillHelper.delete_payment_method(payment_method_id, params[:set_auto_pay_off])
      rescue => e
        flash[:error] = "Error while deleting payment method #{payment_method_id}: #{e.message} #{e.response}"
      end
    else
      flash[:notice] = "Did not get the payment method id"
    end
    redirect_to :back
  end
end
