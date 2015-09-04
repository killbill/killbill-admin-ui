class Kaui::BundlesController < Kaui::EngineController

  def index
    @account = Kaui::Account::find_by_id_or_key(params.require(:account_id), false, false, options_for_klient)
    @bundles = @account.bundles(options_for_klient)

    @tags_per_bundle = {}
    @bundles.each do |bundle|
      # See https://github.com/killbill/killbill/issues/392
      @tags_per_bundle[bundle.bundle_id] = bundle.tags(false, 'NONE', options_for_klient).sort { |tag_a, tag_b| tag_a <=> tag_b }
    end
  end

  def transfer
    @bundle_id = params.require(:id)
  end

  def do_transfer
    new_account = Kaui::Account::find_by_id_or_key(params.require(:new_account_key), false, false, options_for_klient)

    bundle = Kaui::Bundle::new(:bundle_id => params.require(:id), :account_id => new_account.account_id)
    bundle.transfer(nil, params[:billing_policy], current_user.kb_username, params[:reason], params[:comment], options_for_klient)

    redirect_to kaui_engine.account_bundles_path(new_account.account_id), :notice => 'Bundle was successfully transferred'
  end

  def restful_show
    bundle = Kaui::Bundle.find_by_id_or_key(params.require(:id), options_for_klient)
    redirect_to kaui_engine.account_bundles_path(bundle.account_id)
  end
end
