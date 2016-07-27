require 'test_helper'

class Kaui::ChargebacksControllerTest < Kaui::FunctionalTestHelper

  test 'should handle Kill Bill errors in new screen' do
    payment_id = SecureRandom.uuid.to_s
    get :new, :account_id => @account.account_id, :payment_id => payment_id
    assert_redirected_to account_path(@account.account_id)
    assert_equal "Error while communicating with the Kill Bill server: Error 404: Object id=#{payment_id} type=PAYMENT doesn't exist!", flash[:error]
  end

  test 'should get new' do
    get :new, :account_id => @account.account_id, :payment_id => @payment.payment_id
    assert_response 200
  end

  test 'should handle Kill Bill errors during create' do
    payment_id = SecureRandom.uuid.to_s
    post :create,
         :account_id => @payment.account_id,
         :chargeback => {
             :payment_id => payment_id,
             :amount => @payment.paid_amount_to_money.to_f,
             :currency => @payment.currency
         }
    assert_template :new
    assert_equal "Error while creating a new chargeback: Error 404: Object id=#{payment_id} type=PAYMENT doesn't exist!", flash[:error]
  end

  test 'should create chargeback' do
    post :create,
         :account_id => @payment.account_id,
         :chargeback => {
             :payment_id => @payment.payment_id,
             :amount => @payment.paid_amount_to_money.to_f,
             :currency => @payment.currency
         },
         :cancel_all_subs => '1'
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)
    assert_equal 'Chargeback created', flash[:notice]
  end
end
