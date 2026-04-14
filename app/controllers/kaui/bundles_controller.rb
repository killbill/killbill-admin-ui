# frozen_string_literal: true

module Kaui
  class BundlesController < Kaui::EngineController
    # rubocop:disable Lint/HashCompareByIdentity
    def index
      cached_options_for_klient = options_for_klient
      @search_query = params[:q].presence
      @search_by = params[:search_by] || 'bundle_id'
      @per_page = (params[:per_page] || 10).to_i
      @page = (params[:page] || 1).to_i

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

      if @search_query.present?
        @bundles = search_bundles(@search_query, @search_by, cached_options_for_klient)
        @total_pages = 1
        @page = 1
      else
        fetched = Kaui::Account.paginated_bundles(@account.account_id, (@page - 1) * @per_page, @per_page, 'NONE', cached_options_for_klient)
        @bundles = fetched
        @total_pages = (fetched.pagination_max_nb_records.to_f / @per_page).ceil
      end

      @tags_per_bundle = wait(fetch_bundle_tags)
      @tags_per_subscription = wait(fetch_subscription_tags)
      @custom_fields_per_bundle = wait(fetch_bundle_fields)
      @custom_fields_per_subscription = wait(fetch_subscription_fields)
      @available_tags = wait(fetch_available_tags)
      @available_subscription_tags = wait(fetch_available_subscription_tags)

      # Don't load the full catalog to avoid memory issues
      @catalog = nil

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

    private

    def search_bundles(query, search_by, options)
      case search_by
      when 'bundle_id'
        bundle = Kaui::Bundle.find_by_id(query, options)
        bundle ? [bundle] : []
      when 'bundle_external_key'
        bundle = Kaui::Bundle.find_by_external_key(query, false, options)
        bundle ? [bundle] : []
      when 'subscription_id'
        subscription = KillBillClient::Model::Subscription.find_by_id(query, 'NONE', options)
        if subscription
          bundle = Kaui::Bundle.find_by_id(subscription.bundle_id, options)
          bundle ? [bundle] : []
        else
          []
        end
      when 'subscription_external_key'
        subscription = KillBillClient::Model::Subscription.find_by_external_key(query, 'NONE', options)
        if subscription
          bundle = Kaui::Bundle.find_by_id(subscription.bundle_id, options)
          bundle ? [bundle] : []
        else
          []
        end
      else
        []
      end
    rescue StandardError
      []
    end
  end
end
