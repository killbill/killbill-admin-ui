require 'kaui/killbill_helper'

class Kaui::PaymentMethodsController < Kaui::EngineController
  def index
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    search_key = params[:sSearch]
    if search_key.present?
      payment_methods = Kaui::KillbillHelper::search_payment_methods(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      payment_methods = Kaui::KillbillHelper::get_payment_methods(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = payment_methods.pagination_total_nb_records
    json[:iTotalRecords] = payment_methods.pagination_max_nb_records

    payment_methods.each do |payment_method|
      info_plugin = payment_method.plugin_info || OpenStruct.new
      json[:aaData] << [
                         view_context.link_to(payment_method.account_id, view_context.url_for(:controller => :accounts, :action => :show, :id => payment_method.account_id)),
                         info_plugin.external_payment_id,
                         info_plugin.type,
                         info_plugin.cc_name,
                         info_plugin.cc_last4,
                       ]
    end

    respond_to do |format|
      format.json { render :json => json }
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
