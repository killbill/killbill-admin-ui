require 'test_helper'

class Kaui::InvoicesControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index, :account_id => @invoice_item.account_id
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

  test 'should find unpaid invoice by id' do
    get :show, :id => @invoice_item.invoice_id
    assert_response 200

    assert_not_nil assigns(:account)
    assert_not_nil assigns(:invoice)

    assert_equal assigns(:account).account_id, @account.account_id
    assert_equal assigns(:invoice).invoice_id, @invoice_item.invoice_id
  end

  # Test bundles and subscriptions retrieval
  test 'should find invoice by id' do
    get :show, :id => @bundle_invoice.invoice_id
    assert_response 200

    assert_not_nil assigns(:account)
    assert_not_nil assigns(:invoice)

    assert_equal assigns(:account).account_id, @account.account_id
    assert_equal assigns(:invoice).invoice_id, @bundle_invoice.invoice_id
    assert_equal assigns(:subscriptions).size, 1
    assert_equal assigns(:bundles).size, 1

    subscription = assigns(:subscriptions).values.first
    assert_equal subscription.subscription_id, @bundle_invoice.items.first.subscription_id
    assert_equal subscription.subscription_id, @bundle.subscriptions.first.subscription_id

    bundle = assigns(:bundles).values.first
    assert_equal bundle.bundle_id, @bundle_invoice.items.first.bundle_id
    assert_equal bundle.bundle_id, @bundle.bundle_id
  end

  # Test the rendering of the partials
  test 'should find paid invoice by id' do
    get :show, :id => @paid_invoice_item.invoice_id
    assert_response 200

    assert_not_nil assigns(:account)
    assert_not_nil assigns(:invoice)

    assert_equal assigns(:account).account_id, @account.account_id
    assert_equal assigns(:invoice).invoice_id, @paid_invoice_item.invoice_id
  end

  test 'should render HTML invoice' do
    get :show_html, :id => @invoice_item.invoice_id
    assert_response 200
  end
end
