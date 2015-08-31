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

  test 'should handle Kill Bill errors when showing account details' do
    account_id = SecureRandom.uuid.to_s
    get :show, :account_id => account_id
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should find account by id' do
    get :show, :account_id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:account_emails)
    assert_not_nil assigns(:overdue_state)
    assert_not_nil assigns(:payment_methods)
  end

  test 'should handle Kill Bill errors when creating account' do
    post :create
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account', flash[:error]

    external_key = SecureRandom.uuid.to_s
    post :create, :account => {:external_key => external_key}
    assert_redirected_to account_path(assigns(:account).account_id)

    post :create, :account => {:external_key => external_key}
    assert_template :new
    assert_equal "Error while creating account: Error 409: Account already exists for key #{external_key}", flash[:error]
  end

  test 'should create account' do
    get :new
    assert_response 200
    assert_not_nil assigns(:account)

    post :create,
         :account => {
             :name => SecureRandom.uuid.to_s,
             :external_key => SecureRandom.uuid.to_s,
             :email => SecureRandom.uuid.to_s + '@example.com',
             :time_zone => '-06:00',
             :country => 'AR',
             :is_migrated => '1'
         }
    assert_redirected_to account_path(assigns(:account).account_id)
    assert_equal 'Account was successfully created', flash[:notice]

    assert_equal '-06:00', assigns(:account).time_zone
    assert_equal 'AR', assigns(:account).country
    assert assigns(:account).is_migrated
    assert !assigns(:account).is_notified_for_invoices
  end

  test 'should be redirected if no payment_method_id is specified when setting default payment method' do
    put :set_default_payment_method, :account_id => @account.account_id
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: payment_method_id', flash[:error]
  end

  test 'should handle Kill Bill errors when setting default payment method' do
    account_id = SecureRandom.uuid.to_s
    put :set_default_payment_method, :account_id => account_id, :payment_method_id => @payment_method.payment_method_id
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should set default payment method' do
    put :set_default_payment_method, :account_id => @account.account_id, :payment_method_id => @payment_method.payment_method_id
    assert_response 302
  end

  test 'should handle Kill Bill errors when toggling email notifications' do
    account_id = SecureRandom.uuid.to_s
    put :toggle_email_notifications, :account_id => account_id, :is_notified => true
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should toggle email notifications' do
    put :toggle_email_notifications, :account_id => @account.account_id, :is_notified => true
    assert_response 302
  end

  test 'should handle Kill Bill errors when paying all invoices' do
    account_id = SecureRandom.uuid.to_s
    post :pay_all_invoices, :account_id => account_id
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should pay all invoices' do
    post :pay_all_invoices, :account_id => @account.account_id, :is_external_payment => true
    assert_response 302
  end
end
