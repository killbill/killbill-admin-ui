require 'test_helper'

class Kaui::InvoiceItemsControllerTest < Kaui::FunctionalTestHelper

  test 'should get edit' do
    get :edit, :invoice_id => @invoice_item.invoice_id, :id => @invoice_item.invoice_item_id
    assert_response 200
    assert_equal @invoice_item.invoice_item_id, assigns(:invoice_item).invoice_item_id
  end

  test 'should adjust invoice item' do
    put :update,
        :id           => @invoice_item.invoice_item_id,
        :invoice_item => {
            :account_id      => @account.account_id,
            :invoice_id      => @invoice_item.invoice_id,
            :invoice_item_id => @invoice_item.invoice_item_id,
            :amount          => 5.34
        }
    assert_redirected_to invoice_path(assigns(:invoice_item).invoice_id)
    assert_equal 'Adjustment item was successfully created', flash[:notice]
  end

  test 'should delete CBA' do
    delete :destroy,
           :id         => @cba.invoice_item_id,
           :invoice_id => @cba.invoice_id,
           :account_id => @account.account_id
    assert_redirected_to invoice_path(assigns(:invoice_item).invoice_id)
    assert_equal 'CBA item was successfully deleted', flash[:notice]
  end
end
