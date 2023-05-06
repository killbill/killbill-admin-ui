# frozen_string_literal: true

require 'test_helper'

module Kaui
  class RefundsControllerTest < Kaui::FunctionalTestHelper
    test 'should handle Kill Bill errors in new screen' do
      invoice_id = SecureRandom.uuid.to_s
      get :new, params: { account_id: @account.account_id, invoice_id:, payment_id: @payment.payment_id }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]

      payment_id = SecureRandom.uuid.to_s
      get :new, params: { account_id: @account.account_id, invoice_id: @paid_invoice_item.invoice_id, payment_id: }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{payment_id} type=PAYMENT doesn't exist!", flash[:error]
    end

    test 'should get new' do
      get :new, params: { account_id: @account.account_id, invoice_id: @paid_invoice_item.invoice_id, payment_id: @payment.payment_id }
      assert_response 200
      assert_not_nil assigns(:invoice)
      assert_not_nil assigns(:payment)
      assert_not_nil assigns(:refund)
    end

    test 'should create refund without adjustment' do
      refund_amount = @payment.purchased_amount.to_f / 3.0

      post :create,
           params: {
             account_id: @account.account_id,
             invoice_id: @paid_invoice_item.invoice_id,
             payment_id: @payment.payment_id,
             amount: refund_amount,
             adjustment_type: 'noInvoiceAdjustment'
           }
      assert_redirected_to account_invoice_path(@account.account_id, @paid_invoice_item.invoice_id)
    end

    test 'should create refund with invoice adjustment' do
      refund_amount = @payment.purchased_amount.to_f / 3.0

      post :create,
           params: {
             account_id: @account.account_id,
             invoice_id: @paid_invoice_item.invoice_id,
             payment_id: @payment.payment_id,
             amount: refund_amount,
             adjustment_type: 'invoiceAdjustment'
           }
      assert_redirected_to account_invoice_path(@account.account_id, @paid_invoice_item.invoice_id)
    end

    test 'should create refund with invoice item adjustment' do
      refund_amount = @payment.purchased_amount.to_f / 3.0

      post :create,
           params: {
             account_id: @account.account_id,
             invoice_id: @paid_invoice_item.invoice_id,
             payment_id: @payment.payment_id,
             amount: refund_amount,
             adjustment_type: 'invoiceItemAdjustment',
             adjustments: {
               @paid_invoice_item.invoice_item_id => refund_amount
             }
           }
      assert_redirected_to account_invoice_path(@account.account_id, @paid_invoice_item.invoice_id)
    end
  end
end
