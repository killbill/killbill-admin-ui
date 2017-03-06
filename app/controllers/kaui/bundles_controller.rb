class Kaui::BundlesController < Kaui::EngineController

  def index
    fetch_bundles = lambda { @bundles = @account.bundles(options_for_klient) }
    fetch_bundle_tags = lambda {
      all_bundle_tags = @account.all_tags(:BUNDLE, false, 'NONE', options_for_klient)
      @tags_per_bundle = all_bundle_tags.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }

    fetch_available_tags = lambda { @available_tags = Kaui::TagDefinition.all_for_bundle(options_for_klient) }

    run_in_parallel fetch_bundles, fetch_bundle_tags, fetch_available_tags

    @base_subscription = {}
    @bundles.each do |bundle|
      bundle.subscriptions.each do |sub|
        next unless sub.product_category == 'BASE'
        @base_subscription[bundle.bundle_id] = sub
        break
      end
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

  def pause_resume
    @bundle = Kaui::Bundle.find_by_id_or_key(params.require(:id), options_for_klient)
    @base_subscription = @bundle.subscriptions.find { |sub| sub.product_category == 'BASE' }
  end

  def do_pause_resume
    bundle = Kaui::Bundle::new(:bundle_id => params.require(:id))

    paused = false
    resumed = false

    if params[:pause_requested_date].present?
      bundle.pause(params[:pause_requested_date], current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      paused = true
    end

    if params[:resume_requested_date].present?
      bundle.resume(params[:resume_requested_date], current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      resumed = true
    end

    msg = 'Bundle was successfully '
    if paused && !resumed
      msg += 'paused'
    elsif !paused && resumed
      msg += 'resumed'
    else
      msg += 'updated'
    end
    redirect_to kaui_engine.account_bundles_path(@account.account_id), :notice => msg
  end
end
