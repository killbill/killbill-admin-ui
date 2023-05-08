# frozen_string_literal: true

require 'test_helper'

module Kaui
  class InvoiceItemsControllerTest < Kaui::FunctionalTestHelper
    test 'should handle errors in edit screen' do
      get :edit, params: { account_id: @account.account_id, id: @invoice_item.invoice_item_id }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Required parameter missing: invoice_id', flash[:error]

      invoice_id = SecureRandom.uuid.to_s
      get :edit, params: { account_id: @account.account_id, id: @invoice_item.invoice_item_id, invoice_id: }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]

      invoice_item_id = SecureRandom.uuid.to_s
      get :edit, params: { account_id: @account.account_id, id: invoice_item_id, invoice_id: @invoice_item.invoice_id }
      assert_redirected_to account_invoice_path(@account.account_id, @invoice_item.invoice_id)
      assert_equal "Unable to find invoice item #{invoice_item_id}", flash[:error]
    end

    test 'should get edit' do
      get :edit, params: { account_id: @account.account_id, invoice_id: @invoice_item.invoice_id, id: @invoice_item.invoice_item_id }
      assert_response 200
      assert_equal @invoice_item.invoice_item_id, assigns(:invoice_item).invoice_item_id
    end

    test 'should handle errors during update' do
      invoice_id = SecureRandom.uuid.to_s
      put :update,
          params: { id: @invoice_item.invoice_item_id,
                    invoice_item: {
                      account_id: @account.account_id,
                      invoice_id:,
                      invoice_item_id: @invoice_item.invoice_item_id,
                      amount: 5.34,
                      currency: :USD
                    } }
      assert_template :edit
      assert_equal "Error while adjusting invoice item: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
    end

    test 'should adjust invoice item' do
      put :update,
          params: { id: @invoice_item.invoice_item_id,
                    invoice_item: {
                      account_id: @account.account_id,
                      invoice_id: @invoice_item.invoice_id,
                      invoice_item_id: @invoice_item.invoice_item_id,
                      amount: 5.34,
                      currency: :USD
                    } }
      assert_redirected_to account_invoice_path(@account.account_id, assigns(:invoice_item).invoice_id)
      assert_equal 'Adjustment item was successfully created', flash[:notice]
    end

    test 'should handle errors during destroy' do
      delete :destroy, params: { id: @cba.invoice_item_id }
      assert_redirected_to home_path
      assert_equal 'Required parameter missing: invoice_id', flash[:error]

      delete :destroy, params: { id: @cba.invoice_item_id, invoice_id: @cba.invoice_id }
      assert_redirected_to home_path
      assert_equal 'Required parameter missing: account_id', flash[:error]

      invoice_id = SecureRandom.uuid.to_s
      delete :destroy,
             params: {
               id: @cba.invoice_item_id,
               invoice_id:,
               account_id: @account.account_id
             }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: No invoice could be found for id #{invoice_id}.", flash[:error]
    end

    test 'should delete CBA' do
      delete :destroy,
             params: {
               id: @cba.invoice_item_id,
               invoice_id: @cba.invoice_id,
               account_id: @account.account_id
             }
      assert_redirected_to account_invoice_path(@account.account_id, @cba.invoice_id)
      assert_equal 'CBA item was successfully deleted', flash[:notice]
    end
  end
end
