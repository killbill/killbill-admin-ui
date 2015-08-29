require 'test_helper'

class Kaui::SubscriptionsControllerTest < Kaui::FunctionalTestHelper

  test 'should get new page for base plan' do
    get :new,
        :bundle_id        => @bundle.bundle_id,
        :account          => @account.account_id,
        :product_category => 'BASE'
    assert assigns(:plans).size > 0
  end

  test 'should get new page for base addon' do
    get :new,
        :base_product_name => 'Sports',
        :bundle_id         => @bundle.bundle_id,
        :account           => @account.account_id,
        :product_category  => 'ADD_ON'
    assert assigns(:plans).size > 0, 'Plans were not created'
  end

  test 'should create a new base subscription' do
    post :create,
         :subscription => {
             :account_id       => @account.account_id,
             :external_key     => SecureRandom.uuid,
             :product_category => 'BASE'
         },
         :plan_name    => 'standard-monthly'
    assert_response 302
  end

  test 'should create a new addon subscription' do
    post :create,
         :subscription      => {
             :bundle_id        => @bundle.bundle_id,
             :account_id       => @account.account_id,
             :product_category => 'ADD_ON'
         },
         :base_product_name => 'Sports',
         :plan_name         => 'oilslick-monthly'
         assert_includes((200..399), response.code.to_i)
  end

  test 'should get edit page' do
    get :edit, :id => @bundle.subscriptions.first.subscription_id
    assert_response 200
    assert_not_nil assigns(:subscription)
    assert_not_nil assigns(:plans)
    assert_not_nil assigns(:current_plan)
  end

  test 'should update' do
    post :update,
         :id        => @bundle.subscriptions.first.subscription_id,
         :plan_name => 'super-monthly'
    assert_response 302
  end

  test 'should cancel and reinstate subscription' do
    delete :destroy,
           :id                             => @bundle.subscriptions.first.subscription_id,
           :requested_date                 => (Date.today >> 1).to_time.utc.iso8601,
           :use_requested_date_for_billing => '1'
    assert_response 302

    put :reinstate, :id => @bundle.subscriptions.first.subscription_id
    assert_response 302
  end
end
