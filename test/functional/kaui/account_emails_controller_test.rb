require 'test_helper'

class Kaui::AccountEmailsControllerTest < Kaui::FunctionalTestHelper

  test 'should be redirected if no valid account_email was specified during creation' do
    post :create, :account_id => @account.account_id
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: account_email', flash[:error]

    post :create, :account_id => @account.account_id, :account_email => {}
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: account_email', flash[:error]

    post :create, :account_id => @account.account_id, :account_email => {:foo => :bar}
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: email', flash[:error]
  end

  test 'should handle Kill Bill errors during creation' do
    account_id = SecureRandom.uuid.to_s
    post :create,
         :account_id => account_id,
         :account_email => {
             :email => 'toto@example.com'
         }
    assert_redirected_to account_path(account_id)
    assert_equal "Error while communicating with the Kill Bill server: Object id=#{account_id} type=ACCOUNT doesn't exist!", flash[:error]
  end

  test 'should handle Kill Bill errors during deletion' do
    account_id = 'invalid-id'
    delete :destroy, :account_id => account_id, :id => 'toto@example.com'
    assert_redirected_to account_path(account_id)
    assert_equal 'Error while communicating with the Kill Bill server: ', flash[:error]
  end

  test 'should add and destroy email' do
    get :new, :account_id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:account_email)

    email = SecureRandom.uuid.to_s + '@example.com'
    post :create,
         :account_id => @account.account_id,
         :account_email => {
             :email => email
         }
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully added', flash[:notice]

    delete :destroy, :account_id => @account.account_id, :id => email
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully deleted', flash[:notice]
  end
end
