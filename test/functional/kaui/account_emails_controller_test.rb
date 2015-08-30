require 'test_helper'

class Kaui::AccountEmailsControllerTest < Kaui::FunctionalTestHelper

  test 'should add and destroy email' do
    get :new, :account_id => @account.account_id
    assert_response 200
    assert_not_nil assigns(:account_email)

    email = SecureRandom.uuid.to_s + '@example.com'
    post :create,
         :account_email => {
             :account_id => @account.account_id,
             :email      => email
         }
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully added', flash[:notice]

    delete :destroy, :id => @account.account_id, :email => email
    assert_redirected_to account_path(@account.account_id)
    assert_equal 'Account email was successfully deleted', flash[:notice]
  end
end
