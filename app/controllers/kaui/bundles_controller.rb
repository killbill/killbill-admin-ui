class Kaui::BundlesController < Kaui::EngineController

  def index
  end

  def pagination
    search_key = params[:sSearch]
    offset     = params[:iDisplayStart] || 0
    limit      = params[:iDisplayLength] || 10

    bundles = Kaui::Bundle.list_or_search(search_key, offset, limit, options_for_klient)

    json = {
        :sEcho                => params[:sEcho],
        :iTotalRecords        => bundles.pagination_max_nb_records,
        :iTotalDisplayRecords => bundles.pagination_total_nb_records,
        :aaData               => []
    }

    bundles.each do |bundle|
      json[:aaData] << [
          view_context.link_to(view_context.truncate_uuid(bundle.bundle_id), view_context.url_for(:action => :show, :id => bundle.bundle_id)),
          view_context.link_to(view_context.truncate_uuid(bundle.account_id), view_context.url_for(:controller => :accounts, :action => :show, :id => bundle.account_id)),
          bundle.external_key,
          bundle.subscriptions.nil? ? '' : (bundle.subscriptions.map { |s| s.product_name }).join(', ')
      ]
    end

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def show
    begin
      @bundle  = Kaui::Bundle::find_by_id_or_key(params[:id], nil, options_for_klient)
      @account = Kaui::Account::find_by_id(@bundle.account_id, false, false, options_for_klient)
      @tags    = @bundle.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }
    rescue => e
      flash.now[:error] = "Error while retrieving bundle information: #{as_string(e)}"
      render :action => :index
    end
  end

  def transfer
    begin
      @bundle  = Kaui::Bundle::find_by_id_or_key(params[:id], nil, options_for_klient)
      @account = Kaui::Account::find_by_id(@bundle.account_id, false, false, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while preparing to transfer bundle: #{as_string(e)}"
      render :action => :index
    end
  end

  def do_transfer
    key = params[:new_account_key]
    unless key.present?
      flash.now[:error] = 'No new account key given'
      render :action => :index and return
    end

    begin
      # Retrieve the new account to get the account id
      new_account = Kaui::Account::find_by_id_or_key(params[:new_account_key], false, false, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while retrieving new account: #{as_string(e)}"
      render :action => :index and return
    end

    begin
      billing_policy = params[:billing_policy]

      bundle = Kaui::Bundle::new(:bundle_id => params[:id], :account_id => new_account.account_id)
      bundle.transfer(nil, billing_policy, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to account_path(new_account.account_id), :notice => 'Bundle was successfully transferred'
    rescue => e
      flash.now[:error] = "Error while transferring bundle: #{as_string(e)}"
      render :action => :index
    end
  end
end
