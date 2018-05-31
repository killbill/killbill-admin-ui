require 'test_helper'

class Kaui::SubscriptionsControllerTest < Kaui::FunctionalTestHelper

  test 'should handle Kill Bill errors in new screen' do
    bundle_id = SecureRandom.uuid.to_s
    get :new, :bundle_id => bundle_id, :account_id => @account.account_id, :product_category => 'ADD_ON'
    assert_redirected_to account_path(@account.account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{bundle_id} type=BUNDLE doesn't exist!", flash[:error]
  end

  test 'should get new page for base plan' do
    get :new,
        :account_id => @account.account_id,
        :product_category => 'BASE'
    assert assigns(:plans).size > 0
  end

  test 'should get new page for base addon' do
    get :new,
        :base_product_name => 'Sports',
        :bundle_id => @bundle.bundle_id,
        :account_id => @account.account_id,
        :product_category => 'ADD_ON'
    assert assigns(:plans).size > 0, 'Plans were not created'
  end

  test 'should handle errors during creation' do
    post :create,
         :subscription => {
             :bundle_id => @bundle.bundle_id,
             :account_id => @account.account_id,
             :product_category => 'ADD_ON'
         },
         :base_product_name => 'Sports'
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: plan_name', flash[:error]

    post :create,
         :subscription => {
             :bundle_id => @bundle.bundle_id,
             :account_id => @account.account_id,
             :product_category => 'ADD_ON'
         },
         :base_product_name => 'Sports',
         :plan_name => 'not-exists'
    assert_template :new
    assert_equal 'Error while creating the subscription: Unable to find plan not-exists', flash[:error]
  end

  test 'should create a new base subscription' do
    post :create,
         :subscription => {
             :account_id => @account.account_id,
             :external_key => SecureRandom.uuid,
         },
         :plan_name => 'standard-monthly'
    assert_response 302
  end

  test 'should create a new addon subscription' do
    post :create,
         :subscription => {
             :bundle_id => @bundle.bundle_id,
             :account_id => @account.account_id,
             :product_category => 'ADD_ON'
         },
         :base_product_name => 'Sports',
         :plan_name => 'oilslick-monthly'
    assert_includes((200..399), response.code.to_i)
  end

  test 'should handle Kill Bill errors in edit screen' do
    subscription_id = SecureRandom.uuid.to_s
    get :edit, :id => subscription_id
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
  end

  test 'should get edit page' do
    get :edit, :id => @bundle.subscriptions.first.subscription_id
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_not_nil assigns(:plans)
    assert_not_nil assigns(:current_plan)
  end

  test 'should handle errors during update' do
    post :update, :id => @bundle.subscriptions.first.subscription_id
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: plan_name', flash[:error]

    subscription_id = SecureRandom.uuid.to_s
    post :update, :id => subscription_id, :plan_name => 'super-monthly'
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]

    post :update, :id => @bundle.subscriptions.first.subscription_id, :plan_name => 'not-exists'
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 400: Could not find a plan matching spec: (plan: 'not-exists', product: 'undefined', billing period: 'undefined', pricelist 'undefined')", flash[:error]
  end

  test 'should update' do
    post :update,
         :id => @bundle.subscriptions.first.subscription_id,
         :plan_name => 'super-monthly'
    assert_response 302
  end

  test 'should handle errors during destroy' do
    subscription_id = SecureRandom.uuid.to_s
    delete :destroy, :id => subscription_id, :plan_name => 'super-monthly'
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
  end

  test 'should handle errors during reinstate' do
    subscription_id = SecureRandom.uuid.to_s
    put :reinstate, :id => subscription_id
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{subscription_id} type=SUBSCRIPTION doesn't exist!", flash[:error]
  end

  test 'should cancel and reinstate subscription' do
    delete :destroy,
           :id => @bundle.subscriptions.first.subscription_id,
           :requested_date => (Date.today >> 1).to_time.utc.iso8601,
           :use_requested_date_for_billing => '1'
    assert_response 302

    put :reinstate, :id => @bundle.subscriptions.first.subscription_id
    assert_response 302
  end

  test 'should get show' do
    get :show, :id => @bundle.subscriptions.first.subscription_id
    assert_redirected_to account_bundles_path(@bundle.subscriptions.first.account_id)
  end

  test 'should get edit bcd' do
    get :edit_bcd, :id => @bundle.subscriptions.first.subscription_id
    assert_response :success
    assert_equal get_value_from_input_field('subscription_account_id'), @bundle.subscriptions.first.account_id
    assert_equal get_value_from_input_field('subscription_bill_cycle_day_local'), @bundle.subscriptions.first.bill_cycle_day_local.to_s
    assert_equal get_value_from_input_field('effective_from_date'), Date.parse(Time.now.to_s).to_s
  end

  test 'should update bcd' do
    bundle = create_bundle(@account, @tenant)
    parameters = {
        :id => bundle.subscriptions.first.subscription_id,
        :subscription => { :account_id => bundle.subscriptions.first.account_id,
                           :bill_cycle_day_local =>	bundle.subscriptions.first.bill_cycle_day_local
        },
        :effective_from_date => (Date.today >> 1).to_s
    }

    put :update_bcd, parameters
    assert_redirected_to account_bundles_path(bundle.subscriptions.first.account_id)
    assert_equal 'Subscription BCD was successfully changed', flash[:notice]
  end

  test 'should validate external key if found' do
    get :validate_external_key, :external_key => 'foo'
    assert_response :success
    assert_equal JSON[@response.body]['is_found'], false

    get :validate_external_key, :external_key => @bundle.subscriptions.first.external_key
    assert_response :success
    assert_equal JSON[@response.body]['is_found'], true
  end

end
