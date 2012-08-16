class Kaui::BundlesController < Kaui::EngineController

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
        @bundle = Kaui::KillbillHelper.get_bundle_by_external_key(key, params[:account_id])
      end

      if @bundle.present?
        @account = Kaui::KillbillHelper::get_account_by_bundle_id(@bundle.bundle_id)
        @subscriptions = Kaui::KillbillHelper.get_subscriptions_for_bundle(@bundle.bundle_id)
      else
        flash[:error] = "Bundle #{key} not found"
        render :action => :index
      end
    else
      flash[:error] = "No id given"
    end
  end

  def transfer
    bundle_id = params[:id]
    @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
    @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id)

    if @account.nil?
      flash[:error] = "Account not found for bundle id #{bundle_id}"
    end
  end

  def do_transfer
    bundle_id = params[:id]
    key = params[:new_account_key]
    if key.present?
      # support id (UUID) and external key search
      if key =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        result = Kaui::KillbillHelper.get_account(key)
      else
        result = Kaui::KillbillHelper.get_account_by_external_key(key)
      end
      if bundle_id.present? && result.is_a?(Kaui::Account)
        @new_account = result
        success = Kaui::KillbillHelper::transfer_bundle(bundle_id, @new_account.account_id)
        if success
          flash[:info] = "Bundle transfered successfully"
          redirect_to Kaui.account_home_path.call(@new_account.external_key)
          return
        else
          flash[:error] = "Error transfering bundle"
        end
      else
        flash[:error] = "Could not retrieve account #{result}"
      end
    else
      flash[:error] = "No account key given"
    end
    @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
    @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id)
    render :transfer
  end

end