# frozen_string_literal: true

require 'test_helper'

module Kaui
  class SubscriptionsControllerTest < Kaui::FunctionalTestHelper
    OVERRIDE_CATALOG = 'test/fixtures/catalog-sample-for-cancel-subscription.xml'
    test 'should handle Kill Bill errors in new screen' do
      bundle_id = SecureRandom.uuid.to_s
      get :new, params: { bundle_id:, account_id: @account.account_id, product_category: 'ADD_ON' }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{bundle_id} type=BUNDLE doesn't exist!", flash[:error]
    end

    test 'should get new page for base plan' do
      get :new,
          params: {
            account_id: @account.account_id,
            product_category: 'BASE'
          }
      assert assigns(:plans).size.positive?
    end

    test 'should get new page for base addon' do
      get :new,
          params: {
            base_product_name: 'Sports',
            bundle_id: @bundle.bundle_id,
            account_id: @account.account_id,
            product_category: 'ADD_ON'
          }
      assert assigns(:plans).size.positive?, 'Plans were not created'
    end

    test 'should handle errors during creation' do
      post :create,
           params: {
             subscription: {
               bundle_id: @bundle.bundle_id,
               account_id: @account.account_id,
               product_category: 'ADD_ON'
             },
             base_product_name: 'Sports'
           }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Required parameter missing: plan_name', flash[:error]

      post :create,
           params: {
             subscription: {
               bundle_id: @bundle.bundle_id,
               account_id: @account.account_id,
               product_category: 'ADD_ON'
             },
             base_product_name: 'Sports',
             plan_name: 'not-exists'
           }
      assert_template :new
      assert_equal 'Error while creating the subscription: Unable to find plan not-exists', flash[:error]
    end

    test 'should create a new base subscription' do
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               external_key: SecureRandom.uuid
             },
             plan_name: 'standard-monthly'
           }
      assert_response :found
    end

    test 'should support create subscription with bundle external key and subscription external key' do
      external_key = SecureRandom.uuid.to_s
      bundle_external_key = SecureRandom.uuid.to_s
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               external_key:,
               bundle_external_key:
             },
             plan_name: 'standard-monthly'
           }
      assert_response :found
      assert_equal 'Subscription was successfully created', flash[:notice]
      subsciption = @account.bundles(build_options(@tenant)).last.subscriptions.first
      assert_equal subsciption.external_key, external_key
      assert_equal subsciption.bundle_external_key, bundle_external_key
    end

    test 'should support create subscription with bundle external key only' do
      bundle_external_key = SecureRandom.uuid.to_s
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               bundle_external_key:
             },
             plan_name: 'standard-monthly'
           }
      assert_response :found
      assert_equal 'Subscription was successfully created', flash[:notice]
      subsciption = @account.bundles(build_options(@tenant)).last.subscriptions.first
      assert_equal subsciption.bundle_external_key, bundle_external_key
    end

    test 'should support create subscription with subscription external key only' do
      external_key = SecureRandom.uuid.to_s
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               external_key:
             },
             plan_name: 'standard-monthly'
           }
      assert_response :found
      assert_equal 'Subscription was successfully created', flash[:notice]
      subsciption = @account.bundles(build_options(@tenant)).last.subscriptions.first
      assert_equal subsciption.external_key, external_key
    end

    test 'should support create subscription without bundle external key or subscription external key' do
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id
             },
             plan_name: 'standard-monthly'
           }
      assert_response :found
      assert_equal 'Subscription was successfully created', flash[:notice]
    end

    test 'should create a new addon subscription' do
      post :create,
           params: {
             subscription: {
               bundle_id: @bundle.bundle_id,
               account_id: @account.account_id,
               product_category: 'ADD_ON'
             },
             base_product_name: 'Sports',
             plan_name: 'oilslick-monthly'
           }
      assert_includes(200..399, response.code.to_i)
    end

    test 'should handle Kill Bill errors in edit screen' do
      subscription_id = SecureRandom.uuid.to_s
      get :edit, params: { id: subscription_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
    end

    test 'should get edit page' do
      get :edit, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :ok
      assert_not_nil assigns(:subscription)
      assert_not_nil assigns(:plans)
    end

    test 'should handle errors during update' do
      post :update, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_redirected_to edit_subscription_path(@bundle.subscriptions.first.subscription_id)
      assert_equal 'Error while changing subscription: missing parameter plan_name', flash[:error]

      subscription_id = SecureRandom.uuid.to_s
      post :update, params: { id: subscription_id, plan_name: 'super-monthly' }
      assert_redirected_to edit_subscription_path(subscription_id)
      assert_equal "Error while changing subscription: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]

      post :update, params: { id: @bundle.subscriptions.first.subscription_id, plan_name: 'not-exists' }
      assert_redirected_to edit_subscription_path(@bundle.subscriptions.first.subscription_id)
      assert_equal "Error while changing subscription: Could not find any plans named 'not-exists'", flash[:error]
    end

    test 'should update' do
      post :update,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             plan_name: 'super-monthly'
           }
      assert_response :found
    end

    test 'should handle errors during destroy' do
      subscription_id = SecureRandom.uuid.to_s
      delete :destroy, params: { id: subscription_id, plan_name: 'super-monthly' }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
    end

    test 'should handle errors during reinstate' do
      subscription_id = SecureRandom.uuid.to_s
      put :reinstate, params: { id: subscription_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
    end

    test 'should cancel and reinstate subscription' do
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               requested_date: (Time.zone.today >> 1).to_time.utc.iso8601,
               use_requested_date_for_billing: '1'
             }
      assert_response :found

      put :reinstate, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :found
    end

    test 'should cancel by default' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id
             }
      assert_response :found
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Time.zone.today
      assert_equal Date.parse(subscription.billing_end_date), Time.zone.today + 1.month
    end

    test 'should cancel start of term' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'START_OF_TERM'
             }
      assert_response :found
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Time.zone.today
      assert_equal Date.parse(subscription.billing_end_date), Time.zone.today
    end

    test 'should cancel immediate' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'IMMEDIATE'
             }
      assert_response :found
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Time.zone.today
      assert_equal Date.parse(subscription.billing_end_date), Time.zone.today
    end

    test 'should cancel end of term' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'END_OF_TERM'
             }
      assert_response :found
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Date.parse(subscription.billing_start_date) + 1.month
      assert_equal Date.parse(subscription.billing_end_date), Date.parse(subscription.billing_start_date) + 1.month
    end

    test 'should cancel by requested date' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      requested_date = Time.now.utc + 5.days
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               requested_date: requested_date.strftime('%Y-%m-%d'),
               use_requested_date_for_billing: '0'
             }
      assert_response :found

      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), requested_date.to_date
      assert_equal Date.parse(subscription.billing_end_date), Date.parse(subscription.start_date) + 1.month
    end

    test 'should cancel by requested date and use requested date for billing' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      requested_date = Time.now.utc + 5.days
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               requested_date: requested_date.strftime('%Y-%m-%d'),
               use_requested_date_for_billing: '1'
             }
      assert_response :found

      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, 'NONE', build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), requested_date.to_date
      assert_equal Date.parse(subscription.billing_end_date), requested_date.to_date
    end

    test 'should get show' do
      get :show, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_redirected_to account_bundles_path(@bundle.subscriptions.first.account_id)
    end

    test 'should get edit bcd' do
      get :edit_bcd, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :success
      assert_equal extract_value_from_input_field('subscription_account_id'), @bundle.subscriptions.first.account_id
      assert_equal extract_value_from_input_field('subscription_bill_cycle_day_local'), @bundle.subscriptions.first.bill_cycle_day_local.to_s
      assert_equal extract_value_from_input_field('effective_from_date'), Time.zone.today.strftime('%Y-%m-%d')
    end

    test 'should update bcd' do
      bundle = create_bundle(@account, @tenant)
      parameters = {
        id: bundle.subscriptions.first.subscription_id,
        subscription: { account_id: bundle.subscriptions.first.account_id,
                        bill_cycle_day_local: bundle.subscriptions.first.bill_cycle_day_local },
        effective_from_date: (Time.zone.today >> 1).to_s
      }

      put :update_bcd, params: parameters
      assert_redirected_to account_bundles_path(bundle.subscriptions.first.account_id)
      assert_equal 'Subscription BCD was successfully changed', flash[:notice]
    end

    test 'should get block' do
      get :block, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :success
      assert_not_nil assigns(:subscription)
    end

    test 'should handle missing params during do_block' do
      put :do_block, params: { id: @bundle.subscriptions.first.subscription_id, account_id: @account.account_id }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Required parameter missing: state_name', flash[:error]
    end

    test 'should put subscription on block' do
      bundle = create_bundle(@account, @tenant)
      subscription_id = bundle.subscriptions.first.subscription_id

      put :do_block,
          params: {
            id: subscription_id,
            account_id: @account.account_id,
            state_name: 'BLOCKED',
            service: 'kaui-test',
            is_block_billing: '1',
            is_block_entitlement: '1'
          }
      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Blocking state was successfully created', flash[:notice]

      refetched = KillBillClient::Model::AccountTimeline.find_by_account_id(@account.account_id, 'NONE', options).bundles.find { |b| b.bundle_id == bundle.bundle_id }
      event = refetched.subscriptions.flat_map(&:events).find { |e| e.event_type == 'PAUSE_ENTITLEMENT' && e.service_name == 'kaui-test' }
      assert_not_nil event
      assert_equal 'BLOCKED', event.service_state_name
    end

    test 'should get edit quantity' do
      get :edit_quantity, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :success
      assert_equal extract_value_from_input_field('subscription_account_id'), @bundle.subscriptions.first.account_id
      assert_equal extract_value_from_input_field('effective_from_date'), Time.zone.today.strftime('%Y-%m-%d')
    end

    test 'should update quantity' do
      bundle = create_bundle(@account, @tenant)
      subscription_id = bundle.subscriptions.first.subscription_id
      parameters = {
        id: subscription_id,
        subscription: { account_id: bundle.subscriptions.first.account_id,
                        quantity: 2 },
        effective_from_date: (Time.zone.today >> 1).to_s
      }

      put :update_quantity, params: parameters
      assert_redirected_to account_bundles_path(bundle.subscriptions.first.account_id)
      assert_equal 'Subscription quantity was successfully changed', flash[:notice]
    end

    test 'should coerce string quantity to integer' do
      bundle = create_bundle(@account, @tenant)
      parameters = {
        id: bundle.subscriptions.first.subscription_id,
        subscription: { account_id: bundle.subscriptions.first.account_id,
                        quantity: '3' },
        effective_from_date: (Time.zone.today >> 1).to_s
      }

      put :update_quantity, params: parameters
      assert_redirected_to account_bundles_path(bundle.subscriptions.first.account_id)
      assert_equal 'Subscription quantity was successfully changed', flash[:notice]
    end

    test 'should require subscription params on update quantity' do
      put :update_quantity, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_redirected_to edit_quantity_path(@bundle.subscriptions.first.subscription_id)
      assert_equal 'Required parameter missing: subscription', flash[:error]
    end

    test 'should get record usage form' do
      get :record_usage, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response :success
      assert_not_nil assigns(:subscription)
      assert_equal @bundle.subscriptions.first.subscription_id, assigns(:subscription).subscription_id
    end

    test 'should handle Kill Bill errors when loading record usage form' do
      subscription_id = SecureRandom.uuid.to_s
      get :record_usage, params: { id: subscription_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
    end

    test 'should require id when recording usage' do
      assert_raises(ActionController::UrlGenerationError) do
        post :create_usage, params: { unit_type: 'gallons', amount: 10, record_date: Time.now.utc.iso8601 }
      end
    end

    test 'should reject record usage with missing unit type' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: '',
             amount: 10,
             record_date: Time.now.utc.iso8601
           }
      assert_response :success
      assert_template :record_usage
      assert_match(/Unit type is required/, flash.now[:error])
    end

    test 'should reject record usage with non-positive amount' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: 'gallons',
             amount: '0',
             record_date: Time.now.utc.iso8601
           }
      assert_response :success
      assert_template :record_usage
      assert_match(/Amount must be a positive integer/, flash.now[:error])
    end

    test 'should reject record usage with non-integer amount' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: 'gallons',
             amount: '3.5',
             record_date: Time.now.utc.iso8601
           }
      assert_response :success
      assert_template :record_usage
      assert_match(/Amount must be a positive integer/, flash.now[:error])
    end

    test 'should reject record usage with missing date' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: 'gallons',
             amount: 10,
             record_date: ''
           }
      assert_response :success
      assert_template :record_usage
      assert_match(%r{Date/time of usage is required}, flash.now[:error])
    end

    test 'should reject record usage with invalid date format' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: 'gallons',
             amount: 10,
             record_date: 'not-a-date'
           }
      assert_response :success
      assert_template :record_usage
      assert_match(%r{Date/time of usage must be a valid date or datetime}, flash.now[:error])
    end

    test 'should report multiple validation errors at once' do
      post :create_usage,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             unit_type: '',
             amount: '-1',
             record_date: 'bogus'
           }
      assert_response :success
      assert_template :record_usage
      assert_match(/Unit type is required/, flash.now[:error])
      assert_match(/Amount must be a positive integer/, flash.now[:error])
      assert_match(%r{Date/time of usage must be a valid date or datetime}, flash.now[:error])
    end

    test 'should record usage for a usage-based subscription' do
      # Add a usage-based add-on (gas-monthly / gallons) to the existing Sports bundle
      addon = Kaui::Subscription.new(account_id: @account.account_id,
                                     bundle_id: @bundle.bundle_id,
                                     plan_name: 'gas-monthly')
      addon = addon.create('Kaui test', nil, nil, nil, false, build_options(@tenant))

      post :create_usage,
           params: {
             id: addon.subscription_id,
             unit_type: 'gallons',
             amount: 42,
             record_date: Time.now.utc.iso8601
           }
      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Usage was successfully recorded', flash[:notice]
    end

    test 'should display Kill Bill error when recording usage with unknown unit type' do
      stub_usage = Struct.new(:subscription_id, :tracking_id, :unit_usage_records).new
      stub_usage.define_singleton_method(:create) { |*| raise StandardError, 'Unknown unit type: no-such-unit' }

      Kaui::Usage.stub(:new, stub_usage) do
        post :create_usage,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               unit_type: 'no-such-unit',
               amount: 1,
               record_date: Time.now.utc.iso8601
             }
      end
      assert_response :success
      assert_template :record_usage
      assert_not_nil flash.now[:error]
      assert_match(/Error while recording usage/, flash.now[:error])
    end

    test 'should get record usage form with billing meter codes for an Aviate catalog' do
      Dependencies::Aviate::Metering.stub(:aviate_catalog?, true) do
        Dependencies::Aviate::Metering.stub(:billing_meter_codes_for_plan, %w[meter1 meter2]) do
          get :record_usage, params: { id: @bundle.subscriptions.first.subscription_id }
        end
      end
      assert_response :success
      assert assigns(:is_aviate_catalog)
      assert_equal %w[meter1 meter2], assigns(:unit_types)
    end

    test 'should submit usage events via the Aviate metering API for an Aviate catalog' do
      subscription_id = @bundle.subscriptions.first.subscription_id
      received_args = nil
      submit_stub = lambda do |account_id, billing_meter_code, sub_id, tracking_id, timestamp, value, _options|
        received_args = { account_id:, billing_meter_code:, sub_id:, tracking_id:, timestamp:, value: }
        true
      end

      Dependencies::Aviate::Metering.stub(:aviate_catalog?, true) do
        Dependencies::Aviate::Metering.stub(:submit_usage_event, submit_stub) do
          post :create_usage,
               params: {
                 id: subscription_id,
                 unit_type: 'meter1',
                 amount: '1.5',
                 record_date: '2025-01-01T10:30'
               }
        end
      end

      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Usage was successfully recorded', flash[:notice]
      assert_equal @account.account_id, received_args[:account_id]
      assert_equal 'meter1', received_args[:billing_meter_code]
      assert_equal subscription_id, received_args[:sub_id]
      assert_match(/\A[0-9a-f-]{36}\z/i, received_args[:tracking_id])
      assert_equal 1.5, received_args[:value]
    end

    test 'should reject Aviate usage with an invalid tracking id' do
      Dependencies::Aviate::Metering.stub(:aviate_catalog?, true) do
        post :create_usage,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               unit_type: 'meter1',
               amount: '1.5',
               record_date: '2025-01-01T10:30',
               tracking_id: 'not-a-uuid'
             }
      end
      assert_response :success
      assert_template :record_usage
      assert_match(/Tracking ID must be a valid UUID/, flash.now[:error])
    end

    test 'should reject Aviate usage with a non-positive amount but allow decimals' do
      Dependencies::Aviate::Metering.stub(:aviate_catalog?, true) do
        post :create_usage,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               unit_type: 'meter1',
               amount: '0',
               record_date: '2025-01-01T10:30'
             }
      end
      assert_response :success
      assert_template :record_usage
      assert_match(/Amount must be a positive number/, flash.now[:error])
    end

    test 'should validate external key if found' do
      get :validate_external_key, params: { external_key: 'foo' }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], false

      get :validate_external_key, params: { external_key: @bundle.subscriptions.first.external_key }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], true
    end

    test 'should update with price override' do
      post :update,
           params: {
             id: @bundle.subscriptions.first.subscription_id,
             plan_name: 'super-monthly',
             price_overrides: [{ phase_type: 'EVERGREEN', price: 500 }]
           }
      assert_redirected_to account_bundles_path(@bundle.subscriptions.first.account_id)
      assert_equal 'Subscription plan successfully changed', flash[:notice]
    end

    test 'should create with price override' do
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               external_key: SecureRandom.uuid
             },
             price_overrides: [{ phase_type: 'EVERGREEN', price: 500 }],
             plan_name: 'standard-monthly'
           }

      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Subscription was successfully created', flash[:notice]
    end

    test 'should create with multi-phase price overrides' do
      post :create,
           params: {
             subscription: {
               account_id: @account.account_id,
               external_key: SecureRandom.uuid
             },
             price_overrides: [
               { phase_type: 'TRIAL', price: 0 },
               { phase_type: 'EVERGREEN', price: 750 }
             ],
             plan_name: 'standard-monthly'
           }

      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Subscription was successfully created', flash[:notice]
    end

    test 'should linked tag' do
      subscription_id = SecureRandom.uuid.to_s
      options_for_klient = build_options(@tenant)
      tag_definition = Kaui::TagDefinition.new({
                                                 is_control_tag: false,
                                                 name: 'subscription tag',
                                                 description: 'A user-defined tag',
                                                 applicable_object_types: ['SUBSCRIPTION']
                                               })
      tag_definition = tag_definition.create('kaui search test', nil, nil, options_for_klient)
      params = {
        id: subscription_id,
        bundle_id: @bundle.bundle_id,
        "tag_#{tag_definition.id}": 'This is name',
        comment: '',
        commit: 'Update'
      }
      post(:update_tags, params:)
      assert_response :found
    end

    test 'should return raw JSON for show_json' do
      subscription_id = @bundle.subscriptions.first.subscription_id
      get :show_json, params: { id: subscription_id }

      assert_response :ok
      assert_equal 'application/json', @response.media_type

      body = JSON.parse(@response.body)
      assert_equal subscription_id, body['subscriptionId']
      assert_equal @bundle.bundle_id, body['bundleId']
      assert_equal @account.account_id, body['accountId']
    end

    test 'show_json should delegate to find_raw_by_id and return its body verbatim' do
      subscription_id = @bundle.subscriptions.first.subscription_id
      raw_payload = "{\"subscriptionId\":\"#{subscription_id}\",\"note\":\"raw passthrough\"}"

      Kaui::Subscription.stub(:find_raw_by_id, raw_payload) do
        get :show_json, params: { id: subscription_id }
      end

      assert_response :ok
      assert_equal 'application/json', @response.media_type
      assert_equal raw_payload, @response.body
    end

    test 'show_json should surface Kill Bill errors with the original status code' do
      missing_id = SecureRandom.uuid.to_s
      get :show_json, params: { id: missing_id }

      assert_response :not_found
      body = JSON.parse(@response.body)
      assert_includes body['message'].to_s, missing_id
    end

    test 'show_json should require an id' do
      assert_raises(ActionController::UrlGenerationError) do
        get :show_json, params: {}
      end
    end
  end
end
