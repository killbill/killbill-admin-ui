class Kaui::BundlesController < ApplicationController

  def index
    if params[:bundle_id].present?
      redirect_to bundle_path(params[:bundle_id])
    end
  end

  def show
    @external_key = params[:id]
    if @external_key.present?
      @bundle = Kaui::KillbillHelper.get_bundle_by_external_key(@external_key)
      if @bundle.present?
        @subscriptions = Kaui::KillbillHelper.get_subscriptions_for_bundle(@bundle.bundle_id)
      else
        flash[:error] = "Bundle #{@external_key} not found"
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end
end