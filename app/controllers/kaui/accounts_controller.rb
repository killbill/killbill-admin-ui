require 'rest_client'
require 'json'

class Kaui::AccountsController < Kaui::EngineController
  def index
    if params[:account_id].present?
      redirect_to account_path(params[:account_id])
    end
  end

  def show
    key = params[:id]
    if key.present?
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        @account = Kaui::KillbillHelper.get_account(key)
      else
        @account = Kaui::KillbillHelper.get_account_by_external_key(key)
      end

      if @account.present?
        @payment_methods = Kaui::KillbillHelper.get_payment_methods(@account_id)
      else
        flash[:error] = "Account #{@account_id} not found"
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end

  def payment_methods
    @external_key = params[:id]
    if @external_key.present?
      @payment_methods = Kaui::KillbillHelper::get_payment_methods(@external_key)
      unless @payment_methods.is_a?(Array)
        flash[:notice] = "No payment methods for external_key '#{@external_key}'"
        redirect_to :action => :index
        return
      end
    else
      flash[:notice] = "No id given"
    end
  end

  def set_default_payment_method
    @account_id = params[:id]
    # TODO
    redirect_to :back
  end

  def delete_payment_method
    @payment_method_id = params[:payment_method_id]
    if @payment_method_id.present?
      Kaui::KillbillHelper::delete_payment_method(@payment_method_id)
    else
      flash[:notice] = "No id given"
    end
    redirect_to :back
  end
end
