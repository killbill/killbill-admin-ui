require 'test_helper'
require 'functional/kaui/functional_test_helper'

module Kaui
  class InvoicesControllerTest < ActionController::TestCase

    include FunctionalTestHelper

    setup do
      setup_functional_test
    end

    test 'should get index' do
      get :index
      assert_response 200
    end

    test 'should list invoices' do
      # Test pagination
      get :pagination, :format => :json
      verify_pagination_results!
    end

    test 'should search invoices' do
      # Test search
      get :pagination, :sSearch => 'foo', :format => :json
      verify_pagination_results!
    end

    test 'should find invoice by id' do
      get :show, :id => @invoice_item.invoice_id
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:invoice)

      assert_equal assigns(:account).account_id, @account.account_id
      assert_equal assigns(:invoice).invoice_id, @invoice_item.invoice_id
    end

    test 'should render HTML invoice' do
      get :show_html, :id => @invoice_item.invoice_id
      assert_response 200
      assert_nil flash.now[:error]
    end
  end
end
