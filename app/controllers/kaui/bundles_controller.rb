class Kaui::BundlesController < ApplicationController

  def index
    if params[:bundle_id].present?
      redirect_to bundle_path(params[:bundle_id])
    end
  end

  def show
    key = params[:id]
    if key.present?
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        @bundle = Kaui::KillbillHelper.get_bundle(key)
      else
        @bundle = Kaui::KillbillHelper.get_bundle_by_external_key(key)
      end

      if @bundle.present?
        @subscriptions = Kaui::KillbillHelper.get_subscriptions_for_bundle(@bundle.bundle_id)
      else
        flash[:error] = "Bundle #{key} not found"
        redirect_to :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end
end