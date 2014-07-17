require 'test_helper'

module Kaui
  class ChargebacksControllerTest < FunctionalTestHelper

    test 'should get index' do
      get :new, :payment_id => @payment.payment_id
      assert_response 200
    end

    test 'should create payment methods' do
      post :create,
           :chargeback      => {
               :payment_id => @payment.payment_id,
               :amount     => @payment.paid_amount_to_money.to_f,
               :currency   => @payment.currency
           },
           :cancel_all_subs => '1'
      assert_response 302
    end
  end
end
