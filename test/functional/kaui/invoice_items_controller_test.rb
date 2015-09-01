require 'test_helper'

class Kaui::InvoiceItemsControllerTest < Kaui::FunctionalTestHelper

  test 'should handle errors in edit screen' do
    get :edit, :id => @invoice_item.invoice_item_id
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: invoice_id', flash[:error]

    invoice_id = SecureRandom.uuid.to_s
    get :edit, :id => @invoice_item.invoice_item_id, :invoice_id => invoice_id
    assert_redirected_to home_path
    assert_equal "Error while communicating with the Kill Bill server: Error 500: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]

    invoice_item_id = SecureRandom.uuid.to_s
    get :edit, :id => invoice_item_id, :invoice_id => @invoice_item.invoice_id
    assert_redirected_to home_path
    assert_equal "Error: Unable to find invoice item #{invoice_item_id}", flash[:error]
  end

  test 'should get edit' do
    get :edit, :invoice_id => @invoice_item.invoice_id, :id => @invoice_item.invoice_item_id
    assert_response 200
    assert_equal @invoice_item.invoice_item_id, assigns(:invoice_item).invoice_item_id
  end

  test 'should handle errors during update' do
    invoice_id = SecureRandom.uuid.to_s
    put :update,
        :id => @invoice_item.invoice_item_id,
        :invoice_item => {
            :account_id => @account.account_id,
            :invoice_id => invoice_id,
            :invoice_item_id => @invoice_item.invoice_item_id,
            :amount => 5.34
        }
    assert_template :edit
    assert_equal "Error while adjusting invoice item: Error 500: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
  end

  test 'should adjust invoice item' do
    put :update,
        :id => @invoice_item.invoice_item_id,
        :invoice_item => {
            :account_id => @account.account_id,
            :invoice_id => @invoice_item.invoice_id,
            :invoice_item_id => @invoice_item.invoice_item_id,
            :amount => 5.34
        }
    assert_redirected_to account_invoice_path(@account.account_id, assigns(:invoice_item).invoice_id)
    assert_equal 'Adjustment item was successfully created', flash[:notice]
  end

  test 'should handle errors during destroy' do
    delete :destroy, :id => @cba.invoice_item_id
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: invoice_id', flash[:error]

    delete :destroy, :id => @cba.invoice_item_id, :invoice_id => @cba.invoice_id
    assert_redirected_to home_path
    assert_equal 'Required parameter missing: account_id', flash[:error]

    invoice_id = SecureRandom.uuid.to_s
    delete :destroy,
           :id => @cba.invoice_item_id,
           :invoice_id => invoice_id,
           :account_id => @account.account_id
    assert_template :edit
    assert_equal "Error while deleting CBA item: Error 404: No invoice could be found for id #{invoice_id}.", flash[:error]
  end

  test 'should delete CBA' do
    delete :destroy,
           :id => @cba.invoice_item_id,
           :invoice_id => @cba.invoice_id,
           :account_id => @account.account_id
    assert_redirected_to account_invoice_path(@account.account_id, assigns(:invoice_item).invoice_id)
    assert_equal 'CBA item was successfully deleted', flash[:notice]
  end
end
