require 'test_helper'

class Kaui::RefundsControllerTest < Kaui::FunctionalTestHelper

  test 'should create refunds' do
    get :new, :account_id => @account.account_id, :invoice_id => @paid_invoice_item.invoice_id, :payment_id => @payment.payment_id
    assert_response 200
    assert_not_nil assigns(:account)
    assert_not_nil assigns(:invoice)
    assert_not_nil assigns(:payment)

    refund_amount = @payment.purchased_amount.to_f / 3.0

    # Create three refunds
    # TODO test responses

    post :create,
         :account_id      => @account.account_id,
         :invoice_id      => @paid_invoice_item.invoice_id,
         :payment_id      => @payment.payment_id,
         :amount          => refund_amount,
         :adjustment_type => 'noInvoiceAdjustment'
    assert_response 302

    post :create,
         :account_id      => @account.account_id,
         :invoice_id      => @paid_invoice_item.invoice_id,
         :payment_id      => @payment.payment_id,
         :amount          => refund_amount,
         :adjustment_type => 'invoiceAdjustment'
    assert_response 302

    post :create,
         :account_id      => @account.account_id,
         :invoice_id      => @paid_invoice_item.invoice_id,
         :payment_id      => @payment.payment_id,
         :amount          => refund_amount,
         :adjustment_type => 'invoiceItemAdjustment',
         :adjustments     => {
             @paid_invoice_item.invoice_item_id => refund_amount
         }
    assert_response 302
  end
end
