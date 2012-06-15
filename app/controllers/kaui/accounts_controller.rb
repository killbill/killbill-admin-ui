require 'rest_client'
require 'json'

class Kaui::AccountsController < ApplicationController
  def index
    if params[:account_id].present?
      redirect_to account_path(params[:account_id])
    end
  end

  def show
    @account_id = params[:id]
    if @account_id.present?
      @account = Kaui::KillbillHelper.get_account(@account_id)
      if @account.present?
        # TODO: add when payment methods are implemented
        # @payment_methods = Kaui::KillbillHelper.get_payment_methods(@account_id)
        # unless @payment_methods.is_a?(Array)
        #   flash[:error] = "No payment methods for account #{@account_id}"
        #   redirect_to :action => :index
        # end
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
    @external_key = params[:id]
    # TODO
    redirect_to :back
  end

  def delete_payment_method
    @external_key = params[:id]
    @payment_method_id = params[:payment_method_id]
    if @external_key.present? && @payment_method_id.present?
      Kaui::KillbillHelper::delete_payment_method(@external_key, @payment_method_id)
    else
      flash[:notice] = "No id given"
    end
    redirect_to :back
  end
end
