class Kaui::BundlesController < Kaui::EngineController

  def index
    fetch_bundles = promise { @account.bundles(options_for_klient) }
    fetch_bundle_tags = promise {
      all_bundle_tags = @account.all_tags(:BUNDLE, false, 'NONE', options_for_klient)
      all_bundle_tags.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }
    fetch_subscription_tags = promise {
      all_subscription_tags = @account.all_tags(:SUBSCRIPTION, false, 'NONE', options_for_klient)
      all_subscription_tags.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }
    fetch_bundle_fields = promise {
      all_bundle_fields = @account.all_custom_fields(:BUNDLE, 'NONE', options_for_klient)
      all_bundle_fields.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }
    fetch_subscription_fields = promise {
      all_subscription_fields = @account.all_custom_fields(:SUBSCRIPTION, 'NONE', options_for_klient)
      all_subscription_fields.inject({}) {|hsh, entry| (hsh[entry.object_id] ||= []) << entry; hsh}
    }
    fetch_available_tags = promise { Kaui::TagDefinition.all_for_bundle(options_for_klient) }
    fetch_available_subscription_tags = promise { Kaui::TagDefinition.all_for_subscription(options_for_klient) }

    @bundles = wait(fetch_bundles)
    @tags_per_bundle = wait(fetch_bundle_tags)
    @tags_per_subscription = wait(fetch_subscription_tags)
    @custom_fields_per_bundle = wait(fetch_bundle_fields)
    @custom_fields_per_subscription = wait(fetch_subscription_fields)
    @available_tags = wait(fetch_available_tags)
    @available_subscription_tags = wait(fetch_available_subscription_tags)

    @subscription = {}
    @bundles.each do |bundle|
      bundle.subscriptions.each do |sub|
        next if sub.product_category == 'ADD_ON'
        @subscription[bundle.bundle_id] = sub
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
