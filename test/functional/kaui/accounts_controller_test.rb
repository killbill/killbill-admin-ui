require 'test_helper'

class Kaui::AccountsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list accounts' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search accounts' do
    # Test search
    get :pagination, :sSearch => 'foo', :format => :json
    verify_pagination_results!
  end

  test 'should find account by id' do
    get :show, :id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:account_emails)
    assert_not_nil assigns(:overdue_state)
    assert_not_nil assigns(:payment_methods)
    assert_not_nil assigns(:bundles)
  end

  test 'should create account' do
    get :new
    assert_response 200
    assert_not_nil assigns(:account)

    post :create,
         :account => {
             :name         => SecureRandom.uuid.to_s,
             :external_key => SecureRandom.uuid.to_s,
             :email        => SecureRandom.uuid.to_s + '@example.com',
             :time_zone    => '-06:00',
             :country      => 'AR',
             :is_migrated  => '1'
         }
    assert_redirected_to account_path(assigns(:account).account_id)
    assert_equal 'Account was successfully created', flash[:notice]

    assert_equal '-06:00', assigns(:account).time_zone
    assert_equal 'AR', assigns(:account).country
    assert assigns(:account).is_migrated
    assert !assigns(:account).is_notified_for_invoices
  end

  test 'should set default payment method' do
    put :set_default_payment_method, :id => @account.account_id, :payment_method_id => @payment_method.payment_method_id
    assert_response 302
  end

  test 'should toggle email notifications' do
    put :toggle_email_notifications, :id => @account.account_id, :is_notified => true
    assert_response 302
  end

  test 'should pay all invoices' do
    post :pay_all_invoices, :id => @account.account_id, :is_external_payment => true
    assert_response 302
  end
end
