# frozen_string_literal: true

require 'test_helper'

module Kaui
  class InvoicesControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index, params: { account_id: @invoice_item.account_id }
      assert_response 200
    end

    test 'should list invoices' do
      # Test pagination
      get :pagination, params: { format: :json }
      verify_pagination_results!
    end

    test 'should search invoices' do
      # Test search
      get :pagination, params: { search: { search: 'foo' }, format: :json }
      verify_pagination_results!
    end

    test 'should handle Kill Bill errors in show screen' do
      invoice_id = SecureRandom.uuid.to_s
      get :show, params: { account_id: @invoice_item.account_id, id: invoice_id }
      assert_redirected_to account_path(@invoice_item.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
    end

    test 'should find unpaid invoice by id' do
      get :show, params: { account_id: @invoice_item.account_id, id: @invoice_item.invoice_id }
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:invoice)

      assert_equal assigns(:account).account_id, @invoice_item.account_id
      assert_equal assigns(:invoice).invoice_id, @invoice_item.invoice_id
    end

    # Test bundles and subscriptions retrieval
    test 'should find invoice by id' do
      get :show, params: { account_id: @bundle_invoice.account_id, id: @bundle_invoice.invoice_id }
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:invoice)

      assert_equal assigns(:account).account_id, @bundle_invoice.account_id
      assert_equal assigns(:invoice).invoice_id, @bundle_invoice.invoice_id
    end

    # Test the rendering of the partials
    test 'should find paid invoice by id' do
      get :show, params: { account_id: @paid_invoice_item.account_id, id: @paid_invoice_item.invoice_id }
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:invoice)

      assert_equal assigns(:account).account_id, @paid_invoice_item.account_id
      assert_equal assigns(:invoice).invoice_id, @paid_invoice_item.invoice_id
    end

    test 'should handle Kill Bill errors in show_html screen' do
      invoice_id = SecureRandom.uuid.to_s
      get :show_html, params: { id: invoice_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
    end

    test 'should expose restful endpoint' do
      get :restful_show, params: { id: @invoice_item.invoice_id }
      assert_redirected_to account_invoice_path(@invoice_item.account_id, @invoice_item.invoice_id)
    end

    test 'should render HTML invoice' do
      get :show_html, params: { id: @invoice_item.invoice_id }
      assert_response 200
    end

    test 'should commit invoice' do
      invoice_id = create_charge(@account, @tenant).invoice_id

      post :commit_invoice, params: { id: invoice_id }
      assert_redirected_to account_invoice_path(@account.account_id, invoice_id)
      assert_equal 'Invoice successfully committed', flash[:notice]
    end
  end
end
