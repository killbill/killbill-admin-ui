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
        @payment_methods = Kaui::KillbillHelper.get_payment_methods(@account.account_id)
      else
        flash[:error] = "Account #{@account_id} not found"
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end

  def payment_methods
    @account_id = params[:id]
    if @account_id.present?
      @payment_methods = Kaui::KillbillHelper.get_payment_methods(@account_id)
      unless @payment_methods.is_a?(Array)
        flash[:notice] = "No payment methods for account_id '#{@account_id}'"
        redirect_to :action => :index
        return
      end
    else
      flash[:notice] = "No account_id given"
    end
  end

  def set_default_payment_method
    @account_id = params[:id]
    @payment_method_id = params[:payment_method_id]
    if @account_id.present? && @payment_method_id.present?
      @payment_methods = Kaui::KillbillHelper.set_payment_method_as_default(@account_id, @payment_method_id)
    else
      flash[:notice] = "No account_id or payment_method_id given"
    end
    redirect_to :back
  end
end
