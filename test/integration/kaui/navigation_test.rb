require 'test_helper'

module Kaui
  class NavigationTest < IntegrationTestHelper

    test 'Browse one account' do
      get ACCOUNTS_PATH + '/' + @account.account_id
      assert_redirected_to SIGN_IN_PATH

      # Verify log-in and redirect to the original page
      post SIGN_IN_PATH, :params => {:user => {:kb_username => USERNAME, :password => PASSWORD}}
      assert_redirected_to ACCOUNTS_PATH + '/' + @account.account_id

      # User goes to search for the account
      get ACCOUNTS_PATH
      assert_response :success

      # Assumes he found it on the listing
      get ACCOUNTS_PATH + '/' + @account.account_id
      assert_response :success
      check_no_flash_error
      assert_not_nil assigns(:tags)
      assert_not_nil assigns(:account_emails)
      assert_not_nil assigns(:overdue_state)
      assert_not_nil assigns(:payment_methods)

      # He now clicks on the timeline link
      get ACCOUNTS_PATH + '/' + @account.account_id + '/timeline'
      assert_response :success
      check_no_flash_error
      assert_not_nil assigns(:account)

      # Verify log-out
      delete_via_redirect SIGN_OUT_PATH
      assert_equal SIGN_IN_PATH, path
      assert_equal 'You need to sign in or sign up before continuing.', flash[:alert]
    end
  end
end

