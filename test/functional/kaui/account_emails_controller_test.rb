require 'test_helper'

module Kaui
  class AccountEmailsControllerTest < FunctionalTestHelper

    test 'should list emails' do
      get :show, :id => @account.account_id
      assert_response 200
    end

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
      assert_redirected_to account_email_path(@account.account_id)
      assert_equal 'Account email was successfully added', flash[:notice]

      delete :destroy, :id => @account.account_id, :email => email
      assert_redirected_to account_email_path(@account.account_id)
      assert_equal 'Account email was successfully deleted', flash[:notice]
    end
  end
end
