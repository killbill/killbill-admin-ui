require 'test_helper'
require 'functional/kaui/functional_test_helper'

module Kaui
  class AccountTimelinesControllerTest < ActionController::TestCase

    include FunctionalTestHelper

    setup do
      setup_functional_test
    end

    test 'should show the lookup page' do
      get :index
      assert_response 200
    end

    test 'should show the timeline page' do
      get :show, :id => @account.account_id
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:timeline)
      assert_not_nil assigns(:invoices_by_id)

      assert_equal @account.account_id, assigns(:account).account_id
      assert_equal @invoice_item.invoice_id, assigns(:invoices_by_id)[@invoice_item.invoice_id].invoice_id
    end
  end
end
