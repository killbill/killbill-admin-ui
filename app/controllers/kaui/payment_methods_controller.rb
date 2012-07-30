require 'kaui/killbill_helper'

class Kaui::PaymentMethodsController < Kaui::EngineController
  def show
    # TODO: show payment method details
  end

  def destroy
    @payment_method_id = params[:id]
    if @payment_method_id.present?
      Kaui::KillbillHelper.delete_payment_method(@payment_method_id)
    else
      flash[:notice] = "Did not get the payment method id"
    end
    redirect_to :back
  end
end
