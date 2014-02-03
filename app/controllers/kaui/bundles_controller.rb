class Kaui::BundlesController < Kaui::EngineController

  def index
    if params[:bundle_id].present?
      redirect_to kaui_engine.bundle_path(params[:bundle_id])
    end
  end

  def pagination
    json = { :sEcho => params[:sEcho], :iTotalRecords => 0, :iTotalDisplayRecords => 0, :aaData => [] }

    search_key = params[:sSearch]
    if search_key.present?
      bundles = Kaui::KillbillHelper::search_bundles(search_key, params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    else
      bundles = Kaui::KillbillHelper::get_bundles(params[:iDisplayStart] || 0, params[:iDisplayLength] || 10, options_for_klient)
    end
    json[:iTotalDisplayRecords] = bundles.pagination_total_nb_records
    json[:iTotalRecords] = bundles.pagination_max_nb_records

    bundles.each do |bundle|
      json[:aaData] << [
                         view_context.link_to(bundle.bundle_id, view_context.url_for(:action => :show, :id => bundle.bundle_id)),
                         view_context.link_to(bundle.account_id, view_context.url_for(:controller => :accounts, :action => :show, :id => bundle.account_id)),
                         bundle.external_key,
                         bundle.subscriptions.nil? ? '' : (bundle.subscriptions.map { |s| s.product_name }).join(', ')
                       ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def show
    key = params[:id]
    if key.present?
      begin
        @bundle = Kaui::KillbillHelper::get_bundle_by_key(key, params[:account_id], options_for_klient)

        if @bundle.present?
          @account = Kaui::KillbillHelper::get_account(@bundle.account_id, false, false, options_for_klient)
          @subscriptions = @bundle.subscriptions
        else
          flash.now[:error] = "Bundle #{key} not found"
          render :action => :index
        end
      rescue => e
        flash.now[:error] = "Error while retrieving bundle information for #{key}: #{as_string(e)}"
        render :action => :index
      end
    else
      flash.now[:error] = "No id given"
      render :action => :index
    end
  end

  def transfer
    bundle_id = params[:id]
    begin
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id, options_for_klient)
      @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id, options_for_klient)
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
        result = Kaui::KillbillHelper.get_account_by_key(key, false, false, options_for_klient)
      rescue => e
        flash.now[:error] = "Error while retrieving account for #{key}: #{as_string(e)}"
        render :action => :index
        return
      end
      if bundle_id.present? && result.is_a?(Kaui::Account)
        @new_account = result
        begin
          Kaui::KillbillHelper::transfer_bundle(bundle_id, @new_account.account_id, false, true, current_user, params[:reason], params[:comment], options_for_klient)
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
      @bundle = Kaui::KillbillHelper::get_bundle(bundle_id, options_for_klient)
      @account = Kaui::KillbillHelper::get_account_by_bundle_id(bundle_id, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while redirecting: #{as_string(e)}"
      render :transfer
    end
  end
end
