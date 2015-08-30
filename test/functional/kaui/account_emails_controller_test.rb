require 'test_helper'

class Kaui::AccountEmailsControllerTest < Kaui::FunctionalTestHelper

  test 'should be redirected if no account id was specified in new screen' do
    get :new
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account_id', flash[:error]
  end

  test 'should be redirected if no valid account_email was specified during creation' do
    post :create
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account_email', flash[:error]

    post :create, :account_email => {}
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account_email', flash[:error]

    post :create, :account_email => {:account_id => @account.account_id}
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Required parameter missing: email', flash[:error]

    post :create, :account_email => {:email => 'toto@example.com'}
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account_id', flash[:error]
  end

  test 'should handle Kill Bill errors during creation' do
    account_id = SecureRandom.uuid.to_s
    post :create,
         :account_email => {
             :account_id => account_id,
             :email => 'toto@example.com'
         }
    assert_template :new
    assert_equal "Error while adding the email: Error 404: Account does not exist for id #{account_id}", flash[:error]
  end

  test 'should handle Kill Bill errors during deletion' do
    account_id = 'invalid-id'
    delete :destroy, :account_id => account_id, :email => 'toto@example.com'
    assert_redirected_to account_path(account_id)
    assert_equal 'Error while communicating with the Kill Bill server: Error 404: ', flash[:error]
  end

  test 'should add and destroy email' do
    get :new, :account_id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:account_email)

    email = SecureRandom.uuid.to_s + '@example.com'
    post :create,
         :account_email => {
             :account_id => @account.account_id,
             :email => email
         }
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully added', flash[:notice]

    delete :destroy, :account_id => @account.account_id, :email => email
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully deleted', flash[:notice]
  end
end
