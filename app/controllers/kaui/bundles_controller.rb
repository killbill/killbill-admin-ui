class Kaui::BundlesController < Kaui::EngineController

  def index
    @account = Kaui::Account::find_by_id_or_key(params[:account_id], false, false, options_for_klient)
    @bundles = @account.bundles(options_for_klient)

    @tags_per_bundle = {}
    @bundles.each do |bundle|
      @tags_per_bundle[bundle.bundle_id] = bundle.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }
    end
  rescue => e
    flash[:error] = "Error while retrieving account information: #{as_string(e)}"
    redirect_to home_path
  end

  def transfer
    begin
      @bundle = Kaui::Bundle::find_by_id_or_key(params[:id], nil, options_for_klient)
      @account = Kaui::Account::find_by_id(@bundle.account_id, false, false, options_for_klient)
    rescue => e
      flash.now[:error] = "Error while preparing to transfer bundle: #{as_string(e)}"
      render :action => :index
    end
  end

  def do_transfer
    old_account_id = params[:old_account_id]

    key = params[:new_account_key]
    unless key.present?
      flash[:error] = 'No new account key given'
      redirect_to kaui_engine.account_bundles_path(old_account_id) and return
    end

    begin
      # Retrieve the new account to get the account id
      new_account = Kaui::Account::find_by_id_or_key(params[:new_account_key], false, false, options_for_klient)
    rescue => e
      flash[:error] = "Error while retrieving new account: #{as_string(e)}"
      redirect_to kaui_engine.account_bundles_path(old_account_id) and return
    end

    begin
      billing_policy = params[:billing_policy]

      bundle = Kaui::Bundle::new(:bundle_id => params[:id], :account_id => new_account.account_id)
      bundle.transfer(nil, billing_policy, current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_bundles_path(new_account.account_id), :notice => 'Bundle was successfully transferred'
    rescue => e
      flash[:error] = "Error while transferring bundle: #{as_string(e)}"
      redirect_to kaui_engine.account_bundles_path(old_account_id)
    end
  end
end
