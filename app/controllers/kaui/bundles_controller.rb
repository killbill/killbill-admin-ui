class Kaui::BundlesController < Kaui::EngineController

  def index
    if params[:bundle_id].present?
      redirect_to kaui_engine.bundle_path(params[:bundle_id])
    end
  end

  def show
    key = params[:id]
    if key.present?
      begin
        @bundle = Kaui::KillbillHelper::get_bundle_by_key(key, params[:account_id])

        if @bundle.present?
          @account = Kaui::KillbillHelper::get_account_by_bundle_id(@bundle.bundle_id)
          @subscriptions = Kaui::KillbillHelper::get_subscriptions_for_bundle(@bundle.bundle_id)
          @overdue_state = Kaui::KillbillHelper::get_overdue_state_for_bundle(@bundle.bundle_id)
        else
          flash.now[:error] = "Bundle #{key} not found"
          render :action => :index
        end
      rescue => e
        flash.now[:error] = "Error while retrieving bundle information for #{key}: #{as_string(e)}"
      end
    else
      flash.now[:error] = "No id given"
    end
  end

  def transfer
    bundle_id = params[:id]
    begin
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
      @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id)
    rescue => e
      flash.now[:error] = "Error while preparing to transfer bundle: #{as_string(e)}"
    end
    if @account.nil?
      flash.now[:error] = "Account not found for bundle id #{bundle_id}"
    end
  end

  def do_transfer
    bundle_id = params[:id]
    key = params[:new_account_key]
    if key.present?
      begin
        result = Kaui::KillbillHelper.get_account_by_key(key)
      rescue => e
        flash.now[:error] = "Error while retrieving account for #{key}: #{as_string(e)}"
        render :action => :index
        return
      end
      if bundle_id.present? && result.is_a?(Kaui::Account)
        @new_account = result
        begin
          Kaui::KillbillHelper::transfer_bundle(bundle_id, @new_account.account_id)
          flash[:notice] = "Bundle transfered successfully"
        rescue => e
          flash[:error] = "Error transfering bundle #{as_string(e)}"
        end
        redirect_to Kaui.account_home_path.call(@new_account.external_key)
        return
      else
        flash.now[:error] = "Could not retrieve account #{result}"
      end
    else
      flash.now[:error] = "No account key given"
    end

    begin
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id)
      @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id)
    rescue => e
      flash.now[:error] = "Error while redirecting: #{as_string(e)}"
      render :transfer
    end
  end

end
