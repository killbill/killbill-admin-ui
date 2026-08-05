# frozen_string_literal: true

module Kaui
  class SubscriptionsController < Kaui::EngineController
    def show
      restful_show
    end

    def new
      @base_product_name = params[:base_product_name]
      @subscription = Kaui::Subscription.new(bundle_id: params[:bundle_id],
                                             account_id: params[:account_id],
                                             product_category: params[:product_category] || 'BASE')

      @bundle, plans_details = lookup_bundle_and_plan_details(@subscription, @base_product_name)
      @plans = plans_details.map(&:plan)
      @plan_phases = build_plan_phases_map(plans_details)

      return unless @plans.empty?

      flash[:error] = if @subscription.product_category == 'BASE'
                        'No plan available in the catalog'
                      else
                        "No add-on available in the catalog for product #{@base_product_name}"
                      end
      redirect_to kaui_engine.account_bundles_path(@subscription.account_id), error: 'No available plan'
    end

    def edit
      @subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
      _, plans_details = lookup_bundle_and_plan_details(@subscription)
      # Use a Set to deal with multiple pricelists
      @plans = Set.new.merge(plans_details.map(&:plan))
      @plan_phases = build_plan_phases_map(plans_details)
    end

    def create
      plan_name = params.require(:plan_name)
      @base_product_name = params[:base_product_name]
      @subscription = Kaui::Subscription.new(params.require(:subscription).permit!.to_h.compact_blank)

      begin
        @bundle, plans_details = lookup_bundle_and_plan_details(@subscription, @base_product_name)

        plan_details = plans_details.find { |p| p.plan == plan_name }
        raise "Unable to find plan #{plan_name}" if plan_details.nil?

        @subscription.plan_name = plan_name
        requested_date = params[:type_change] == 'DATE' ? params[:requested_date].presence : nil

        overrides = price_overrides(plan_details)
        @subscription.price_overrides = overrides if overrides.present?
        @subscription.quantity = params[:quantity].to_i if params[:quantity].present? && params[:quantity].to_i.positive?

        # un-set product_category since is not needed if plan name exist
        @subscription.product_category = nil
        @subscription = @subscription.create(current_user.kb_username, params[:reason], params[:comment], requested_date, false, options_for_klient)
        redirect_to kaui_engine.account_bundles_path(@subscription.account_id), notice: 'Subscription was successfully created'
      rescue StandardError => e
        @plans = plans_details.nil? ? [] : plans_details.map(&:plan)

        if e.is_a?(::KillBillClient::API::BadRequest) && !e.response.nil? && !e.response.body.nil?
          error_message = begin
            JSON.parse(e.response.body)
          rescue StandardError
            nil
          end
          if (!error_message.nil? & !error_message['code'].nil?) && error_message['code'] == 2010 # CAT_NO_PRICE_FOR_CURRENCY
            # Hack for lack of proper Kill Bill messaging (https://github.com/killbill/killbill-admin-ui/issues/266)
            flash.now[:error] = "Unable to create the subscription: a price for this currency hasn't been specified in the catalog"
            render :new and return
          end
        end

        flash.now[:error] = "Error while creating the subscription: #{as_string(e)}"
        render :new
      end
    end

    def update
      plan_name = params.require(:plan_name)

      requested_date = params[:type_change] == 'DATE' ? params[:requested_date].presence : nil
      billing_policy = params[:type_change] == 'POLICY' ? params[:policy].presence : nil

      wait_for_completion = params[:wait_for_completion] == '1'

      subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)

      input = { planName: plan_name }

      _, plans_details = lookup_bundle_and_plan_details(subscription)
      plan_details = plans_details.find { |p| p.plan == plan_name }
      overrides = plan_details ? price_overrides(plan_details) : nil
      input[:priceOverrides] = overrides if overrides.present?

      subscription.change_plan(input,
                               current_user.kb_username,
                               params[:reason],
                               params[:comment],
                               requested_date,
                               billing_policy,
                               nil,
                               wait_for_completion,
                               options_for_klient)

      redirect_to kaui_engine.account_bundles_path(subscription.account_id), notice: 'Subscription plan successfully changed'
    rescue StandardError => e
      redirect_to edit_subscription_path(params.require(:id)), flash: { error: "Error while changing subscription: #{as_string(e)}" }
    end

    def destroy
      requested_date = params[:requested_date].presence
      billing_policy = params[:policy].presence
      # START_OF_TERM is *not* a valid entitlement_policy and so would default to IMMEDIATE
      entitlement_policy = billing_policy && billing_policy == 'START_OF_TERM' ? 'IMMEDIATE' : billing_policy

      # true by default except default policy
      use_requested_date_for_billing = if requested_date
                                         (params[:use_requested_date_for_billing] || '1') == '1'
                                       else
                                         nil
                                       end
      subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
      subscription.cancel(current_user.kb_username, params[:reason], params[:comment], requested_date, entitlement_policy, billing_policy, use_requested_date_for_billing, options_for_klient)
      redirect_to kaui_engine.account_bundles_path(subscription.account_id), notice: 'Subscription was successfully cancelled'
    end

    def reinstate
      subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)

      subscription.uncancel(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

      redirect_to kaui_engine.account_bundles_path(subscription.account_id), notice: 'Subscription was successfully reinstated'
    end

    def edit_bcd
      @subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
    end

    def update_bcd
      input_subscription = params.require(:subscription)
      subscription = Kaui::Subscription.new
      subscription.subscription_id = params.require(:id)
      subscription.bill_cycle_day_local = input_subscription['bill_cycle_day_local']

      effective_from_date = params['effective_from_date']

      subscription.update_bcd(current_user.kb_username, params[:reason], params[:comment], effective_from_date, nil, options_for_klient)
      redirect_to kaui_engine.account_bundles_path(input_subscription['account_id']), notice: 'Subscription BCD was successfully changed'
    end

    def edit_quantity
      @subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
    end

    def update_quantity
      id = params.require(:id)
      input_subscription = params.require(:subscription)

      quantity_raw = input_subscription['quantity'].to_s.strip
      quantity = Integer(quantity_raw, exception: false)
      if quantity.nil? || quantity <= 0
        flash.now[:error] = 'Quantity must be a positive integer'
        @subscription = Kaui::Subscription.find_by_id(id, 'NONE', options_for_klient)
        @subscription.quantity = quantity_raw
        render :edit_quantity and return
      end

      subscription = Kaui::Subscription.new
      subscription.subscription_id = id
      subscription.quantity = quantity

      effective_from_date = params['effective_from_date']

      subscription.update_quantity(current_user.kb_username, params[:reason], params[:comment], effective_from_date, nil, options_for_klient)
      redirect_to kaui_engine.account_bundles_path(input_subscription['account_id']), notice: 'Subscription quantity was successfully changed'
    rescue ActionController::ParameterMissing
      redirect_to kaui_engine.edit_quantity_path(params[:id]), flash: { error: 'Required parameter missing: subscription' }
    end

    def record_usage
      @subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
      @is_aviate_catalog = Dependencies::Aviate::Metering.aviate_catalog?(@subscription.account_id, options_for_aviate_klient)
      @unit_types = if @is_aviate_catalog
                      Dependencies::Aviate::Metering.billing_meter_codes_for_plan(@subscription.plan_name, @subscription.account_id, options_for_aviate_klient)
                    else
                      fetch_unit_types_from_subscription(@subscription)
                    end
    end

    def create_usage
      subscription_id = params.require(:id)
      unit_type = params[:unit_type].to_s.strip
      amount_raw = params[:amount].to_s.strip
      record_date = params[:record_date].to_s.strip
      tracking_id = params[:tracking_id].to_s.strip

      @subscription = Kaui::Subscription.find_by_id(subscription_id, 'NONE', options_for_klient)
      @is_aviate_catalog = Dependencies::Aviate::Metering.aviate_catalog?(@subscription.account_id, options_for_aviate_klient)

      # Input validation
      errors = []
      errors << (@is_aviate_catalog ? 'Billing meter code is required' : 'Unit type is required') if unit_type.blank?
      errors << 'Amount is required' if amount_raw.blank?
      amount = @is_aviate_catalog ? parse_usage_amount(amount_raw) : Integer(amount_raw, exception: false)
      errors << (@is_aviate_catalog ? 'Amount must be a positive number' : 'Amount must be a positive integer') if amount.nil? || amount <= 0
      errors << 'Date/time of usage is required' if record_date.blank?
      parsed_date = parse_usage_date(record_date) if record_date.present?
      errors << 'Date/time of usage must be a valid date or datetime' if record_date.present? && parsed_date.nil?
      errors << 'Tracking ID must be a valid UUID' if @is_aviate_catalog && tracking_id.present? && !tracking_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)

      if errors.any?
        flash.now[:error] = errors.join('. ')
        @unit_types = fetch_unit_types_for_record_usage_form(@subscription, @is_aviate_catalog)
        @unit_type = unit_type
        @amount = amount_raw
        @record_date = record_date
        @tracking_id = tracking_id
        render :record_usage and return
      end

      begin
        if @is_aviate_catalog
          # trackingId is required by the Aviate metering API; auto-generate one if the user left it blank
          tracking_id = SecureRandom.uuid if tracking_id.blank?
          Dependencies::Aviate::Metering.submit_usage_event(@subscription.account_id, unit_type, subscription_id, tracking_id,
                                                            parsed_date.utc.strftime('%Y-%m-%dT%H:%M:%S'), amount.to_f, options_for_aviate_klient)
        else
          usage_record = KillBillClient::Model::UsageRecordAttributes.new
          usage_record.record_date = parsed_date.utc.iso8601
          usage_record.amount = amount.to_i

          unit_usage_record = KillBillClient::Model::UnitUsageRecordAttributes.new
          unit_usage_record.unit_type = unit_type
          unit_usage_record.usage_records = [usage_record]

          usage = Kaui::Usage.new
          usage.subscription_id = subscription_id
          usage.tracking_id = tracking_id.presence
          usage.unit_usage_records = [unit_usage_record]

          usage.create(current_user.kb_username, nil, nil, options_for_klient)
        end

        redirect_to kaui_engine.account_bundles_path(@subscription.account_id), notice: 'Usage was successfully recorded'
      rescue StandardError => e
        Rails.logger.error("Failed to record usage for subscription #{subscription_id}: #{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
        flash.now[:error] = "Error while recording usage: #{as_string(e)}"
        @unit_types = fetch_unit_types_for_record_usage_form(@subscription, @is_aviate_catalog)
        @unit_type = unit_type
        @amount = amount_raw
        @record_date = record_date
        @tracking_id = tracking_id
        render :record_usage
      end
    end

    def restful_show
      subscription = Kaui::Subscription.find_by_id(params.require(:id), 'NONE', options_for_klient)
      redirect_to kaui_engine.account_bundles_path(subscription.account_id)
    end

    def show_json
      raw_body = Kaui::Subscription.find_raw_by_id(params.require(:id), 'NONE', options_for_klient)
      render body: raw_body, content_type: 'application/json'
    rescue KillBillClient::API::ResponseError => e
      render body: e.response.body, content_type: 'application/json', status: e.code
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end

    def validate_bundle_external_key
      json_response do
        external_key = params.require(:external_key)

        begin
          bundle = Kaui::Bundle.find_by_external_key(external_key, false, options_for_klient)
        rescue KillBillClient::API::NotFound
          bundle = nil
        end

        { is_found: !bundle.nil? }
      end
    end

    def validate_external_key
      json_response do
        external_key = params.require(:external_key)

        begin
          subscription = Kaui::Subscription.find_by_external_key(external_key, 'NONE', options_for_klient)
        rescue KillBillClient::API::NotFound
          subscription = nil
        end

        { is_found: !subscription.nil? }
      end
    end

    def update_tags
      subscription_id = params.require(:id)
      subscription = Kaui::Subscription.find_by_id(subscription_id, 'NONE', options_for_klient)
      tags = []
      params.each_key do |key|
        next unless key.include? 'tag'

        tag_info = key.split('_')
        next if (tag_info.size != 2) || (tag_info[0] != 'tag')

        tags << tag_info[1]
      end

      Kaui::Tag.set_for_subscription(subscription_id, tags, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_bundles_path(subscription.account_id), notice: 'Subscription tags successfully set'
    end

    private

    def lookup_bundle_and_plan_details(subscription, base_product_name = nil)
      if subscription.product_category == 'ADD_ON'
        bundle = Kaui::Bundle.find_by_id(subscription.bundle_id, options_for_klient)
        if base_product_name.blank?
          bundle.subscriptions.each do |sub|
            if sub.product_category == 'BASE'
              base_product_name = sub.product_name
              break
            end
          end
        end
        plans_details = Kaui::Catalog.available_addons(base_product_name, subscription.account_id, options_for_klient)
      else
        bundle = nil
        plans_details = catalog_plans(subscription.product_category == 'BASE' ? nil : subscription.product_category, subscription.account_id)
      end
      [bundle, plans_details]
    end

    def catalog_plans(product_category = nil, account_id = nil)
      return Kaui::Catalog.available_base_plans(account_id, options_for_klient) if product_category == 'BASE'

      options = options_for_klient

      catalog = Kaui::Catalog.get_tenant_catalog_json(DateTime.now.to_s, account_id, options)
      return [] if catalog.blank?

      plans = []
      catalog[-1].products.each do |product|
        next if product.type == 'ADD_ON' || (!product_category.nil? && product.type != product_category)

        product.plans.each do |plan|
          class << plan
            attr_accessor :plan
          end
          plan.plan = plan.name

          plans << plan
        end
      end

      plans
    end

    def price_overrides(plan_details)
      raw = params[:price_overrides]
      return nil if raw.blank?

      entries = raw.respond_to?(:values) ? raw.values : Array(raw)
      phase_meta = plan_details.respond_to?(:phases) ? (plan_details.phases || []).index_by(&:type) : {}

      overrides = entries.filter_map do |entry|
        entry = entry.to_unsafe_h if entry.respond_to?(:to_unsafe_h)
        entry = entry.with_indifferent_access if entry.respond_to?(:with_indifferent_access)

        price_str = entry[:price].to_s.strip
        phase_type = entry[:phase_type].to_s.strip

        price = BigDecimal(price_str, exception: false)

        next if price.nil? || phase_type.blank? || price.negative?

        phase = phase_meta[phase_type]
        next if phase.nil?

        override = KillBillClient::Model::PhasePriceAttributes.new
        override.phase_type = phase_type
        if phase_uses_fixed_price?(phase)
          override.fixed_price = price.to_s('F')
        else
          override.recurring_price = price.to_s('F')
        end
        override
      end

      overrides.presence
    end

    def build_plan_phases_map(plans_details)
      (plans_details || []).to_h do |pd|
        # PlanDetail objects returned by available_base_plans/available_addons only expose the
        # final phase (product/plan/priceList/finalPhaseBillingPeriod/finalPhaseRecurringPrice)
        # and have no phases method, unlike full catalog Plan objects. Skip phase overrides for those.
        phases = if pd.respond_to?(:phases)
                   (pd.phases || []).map do |ph|
                     fixed = phase_uses_fixed_price?(ph)
                     prices = ph.prices || []
                     price_label = if fixed
                                     '$0.00'
                                   elsif prices.any?
                                     format('$%.2f', prices.first.value.to_f)
                                   else
                                     ''
                                   end
                     { type: ph.type, fixed: fixed, priceLabel: price_label }
                   end
                 else
                   []
                 end
        [pd.plan, phases]
      end
    end

    def phase_uses_fixed_price?(phase)
      (phase.prices || []).empty?
    end

    def fetch_unit_types_for_record_usage_form(subscription, is_aviate_catalog)
      if is_aviate_catalog
        Dependencies::Aviate::Metering.billing_meter_codes_for_plan(subscription.plan_name, subscription.account_id, options_for_aviate_klient)
      else
        fetch_unit_types_from_subscription(subscription)
      end
    end

    # The Aviate plugin's catalog/metering endpoints require a JWT (obtained by logging in via the
    # Aviate Configuration page in killbill-aviate-ui), stored in a jwt_token cookie - same convention
    # as Aviate::EngineController#options_for_klient in that engine.
    def options_for_aviate_klient
      options_for_klient(jwt_token: cookies[:jwt_token])
    end

    def parse_usage_amount(amount_raw)
      BigDecimal(amount_raw, exception: false)
    rescue ArgumentError
      nil
    end

    def fetch_unit_types_from_subscription(subscription)
      unit_types = []
      (subscription.prices || []).each do |phase_price|
        usage_prices = if phase_price.is_a?(Hash)
                         phase_price['usagePrices'] || phase_price[:usagePrices] || []
                       elsif phase_price.respond_to?(:usage_prices)
                         phase_price.usage_prices || []
                       else
                         []
                       end
        (usage_prices || []).each do |usage_price|
          tier_prices = if usage_price.is_a?(Hash)
                          usage_price['tierPrices'] || usage_price[:tierPrices] || []
                        elsif usage_price.respond_to?(:tier_prices)
                          usage_price.tier_prices || []
                        else
                          []
                        end
          (tier_prices || []).each do |tier_price|
            block_prices = if tier_price.is_a?(Hash)
                             tier_price['blockPrices'] || tier_price[:blockPrices] || []
                           elsif tier_price.respond_to?(:block_prices)
                             tier_price.block_prices || []
                           else
                             []
                           end
            (block_prices || []).each do |block_price|
              unit_name = if block_price.is_a?(Hash)
                            block_price['unitName'] || block_price[:unitName] || block_price['unit_name']
                          elsif block_price.respond_to?(:unit_name)
                            block_price.unit_name
                          end
              unit_types << unit_name if unit_name.present?
            end
          end
        end
      end
      unit_types.uniq
    rescue StandardError => e
      Rails.logger.warn("Failed to extract unit types from subscription #{subscription&.subscription_id}: #{e.class}: #{e.message}")
      []
    end

    def parse_usage_date(str)
      str = str.to_s.strip
      return nil if str.empty?

      if str.match?(/^\d{4}-\d{2}-\d{2}$/)
        year, month, day = str.split('-').map(&:to_i)
        Time.utc(year, month, day)
      elsif str.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/)
        Time.iso8601("#{str}:00Z")
      else
        Time.iso8601(str)
      end
    rescue ArgumentError
      nil
    end
  end
end
