require 'test_helper'

module Kaui
  class AccountsControllerTest < FunctionalTestHelper

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

    test 'should find correct positive balance' do
      accnt = accounts(:account_with_positive_balance)

      get :show, :id => accnt["accountId"], :use_route => 'kaui'
      assert_response :success
      assert assigns(:account).balance > 0
    end
  end
end
