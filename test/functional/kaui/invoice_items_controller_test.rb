require 'test_helper'

class Kaui::InvoiceItemsControllerTest < ActionController::TestCase
  fixtures :invoice_items

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should find invoice item by id" do
    item = invoice_items(:recurring_item_for_pierre)

    get :show, :id => item["invoiceItemId"], :invoice_id => item["invoiceId"]
    assert_response :success
    assert_equal assigns(:invoice_item).invoice_item_id, item["invoiceItemId"]
  end
end
