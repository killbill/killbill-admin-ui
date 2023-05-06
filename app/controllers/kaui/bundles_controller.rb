# frozen_string_literal: true

module Kaui
  class BundlesController < Kaui::EngineController
    # rubocop:disable Lint/HashCompareByIdentity
    def index
      cached_options_for_klient = options_for_klient

      fetch_bundles = promise { @account.bundles(cached_options_for_klient) }
      fetch_bundle_tags = promise do
        all_bundle_tags = @account.all_tags(:BUNDLE, false, 'NONE', cached_options_for_klient)
        all_bundle_tags.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end
      fetch_subscription_tags = promise do
        all_subscription_tags = @account.all_tags(:SUBSCRIPTION, false, 'NONE', cached_options_for_klient)
        all_subscription_tags.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end
      fetch_bundle_fields = promise do
        all_bundle_fields = @account.all_custom_fields(:BUNDLE, 'NONE', cached_options_for_klient)
        all_bundle_fields.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end
      fetch_subscription_fields = promise do
        all_subscription_fields = @account.all_custom_fields(:SUBSCRIPTION, 'NONE', cached_options_for_klient)
        all_subscription_fields.each_with_object({}) do |entry, hsh|
          (hsh[entry.object_id] ||= []) << entry
        end
      end
      fetch_available_tags = promise { Kaui::TagDefinition.all_for_bundle(cached_options_for_klient) }
      fetch_available_subscription_tags = promise { Kaui::TagDefinition.all_for_subscription(cached_options_for_klient) }

      @bundles = wait(fetch_bundles)
      @tags_per_bundle = wait(fetch_bundle_tags)
      @tags_per_subscription = wait(fetch_subscription_tags)
      @custom_fields_per_bundle = wait(fetch_bundle_fields)
      @custom_fields_per_subscription = wait(fetch_subscription_fields)
      @available_tags = wait(fetch_available_tags)
      @available_subscription_tags = wait(fetch_available_subscription_tags)

      # TODO: This doesn't take into account catalog versions
      catalogs = Kaui::Catalog.get_account_catalog_json(@account.account_id, nil, cached_options_for_klient) || []
      @catalog = catalogs[-1]

      @subscription = {}
      @bundles.each do |bundle|
        bundle.subscriptions.each do |sub|
          next if sub.product_category == 'ADD_ON'

          @subscription[bundle.bundle_id] = sub
          break
        end
      end
    end
    # rubocop:enable Lint/HashCompareByIdentity

    def transfer
      @bundle_id = params.require(:id)
    end

    def do_transfer
      cached_options_for_klient = options_for_klient

      new_account = Kaui::Account.find_by_id_or_key(params.require(:new_account_key), false, false, cached_options_for_klient)

      bundle = Kaui::Bundle.new(bundle_id: params.require(:id), account_id: new_account.account_id)
      bundle.transfer(nil, params[:billing_policy], current_user.kb_username, params[:reason], params[:comment], cached_options_for_klient)

      redirect_to kaui_engine.account_bundles_path(new_account.account_id), notice: 'Bundle was successfully transferred'
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
      bundle = Kaui::Bundle.new(bundle_id: params.require(:id))

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
      msg += if paused && !resumed
               'paused'
             elsif !paused && resumed
               'resumed'
             else
               'updated'
             end
      redirect_to kaui_engine.account_bundles_path(@account.account_id), notice: msg
    end
  end
end
