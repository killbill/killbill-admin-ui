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
      assert_response 302
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
      assert_includes((200..399), response.code.to_i)
    end

    test 'should handle Kill Bill errors in edit screen' do
      subscription_id = SecureRandom.uuid.to_s
      get :edit, params: { id: subscription_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
    end

    test 'should get edit page' do
      get :edit, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response 200
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
      assert_response 302
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
               requested_date: (Date.today >> 1).to_time.utc.iso8601,
               use_requested_date_for_billing: '1'
             }
      assert_response 302

      put :reinstate, params: { id: @bundle.subscriptions.first.subscription_id }
      assert_response 302
    end

    test 'should cancel by default' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id
             }
      assert_response 302
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Date.today
      assert_equal Date.parse(subscription.billing_end_date), Date.today + 1.month
    end

    test 'should cancel start of term' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'START_OF_TERM'
             }
      assert_response 302
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Date.today
      assert_equal Date.parse(subscription.billing_end_date), Date.today
    end

    test 'should cancel immediate' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'IMMEDIATE'
             }
      assert_response 302
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
      assert_equal Date.parse(subscription.cancelled_date), Date.today
      assert_equal Date.parse(subscription.billing_end_date), Date.today
    end

    test 'should cancel end of term' do
      setup_functional_test(1, true, catalog_file: OVERRIDE_CATALOG)
      delete :destroy,
             params: {
               id: @bundle.subscriptions.first.subscription_id,
               policy: 'END_OF_TERM'
             }
      assert_response 302
      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
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
      assert_response 302

      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
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
      assert_response 302

      subscription = Kaui::Subscription.find_by_id(@bundle.subscriptions.first.subscription_id, build_options(@tenant))
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
      assert_equal extract_value_from_input_field('effective_from_date'), Date.parse(Time.now.to_s).to_s
    end

    test 'should update bcd' do
      bundle = create_bundle(@account, @tenant)
      parameters = {
        id: bundle.subscriptions.first.subscription_id,
        subscription: { account_id: bundle.subscriptions.first.account_id,
                        bill_cycle_day_local: bundle.subscriptions.first.bill_cycle_day_local },
        effective_from_date: (Date.today >> 1).to_s
      }

      put :update_bcd, params: parameters
      assert_redirected_to account_bundles_path(bundle.subscriptions.first.account_id)
      assert_equal 'Subscription BCD was successfully changed', flash[:notice]
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
             price_override: 500
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
             price_override: 500,
             plan_name: 'standard-monthly'
           }

      assert_redirected_to account_bundles_path(@account.account_id)
      assert_equal 'Subscription was successfully created', flash[:notice]
    end
  end
end
