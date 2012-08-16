require 'test_helper'

class Kaui::InvoicesControllerTest < ActionController::TestCase
  fixtures :accounts, :invoices

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should find invoice by id" do
    pierre = accounts(:pierre)
    invoice = invoices(:invoice_for_pierre)

    get :show, :id => invoice["invoiceId"]
    assert_response :success
    assert_equal assigns(:account).account_id, pierre["accountId"]
    assert_equal assigns(:invoice).invoice_id, invoice["invoiceId"]
    assert_equal assigns(:invoice).account_id, pierre["accountId"]
  end
end