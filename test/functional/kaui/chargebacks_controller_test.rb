# frozen_string_literal: true

require 'test_helper'

module Kaui
  class ChargebacksControllerTest < Kaui::FunctionalTestHelper
    test 'should handle Kill Bill errors in new screen' do
      payment_id = SecureRandom.uuid.to_s
      get :new, params: { account_id: @account.account_id, payment_id: }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{payment_id} type=PAYMENT doesn't exist!", flash[:error]
    end

    test 'should get new' do
      get :new, params: { account_id: @account.account_id, payment_id: @payment.payment_id }
      assert_response 200
    end

    test 'should handle Kill Bill errors during create' do
      payment_id = SecureRandom.uuid.to_s
      post :create,
           params: {
             account_id: @account.account_id,
             chargeback: {
               payment_id:,
               amount: @payment.paid_amount_to_money.to_f,
               currency: @payment.currency
             }
           }
      assert_template :new
      assert_equal "Error while creating a new chargeback: Object id=#{payment_id} type=PAYMENT doesn't exist!", flash[:error]
    end

    test 'should create chargeback' do
      post :create,
           params: {
             account_id: @payment.account_id,
             chargeback: {
               payment_id: @payment.payment_id,
               amount: @payment.paid_amount_to_money.to_f,
               currency: @payment.currency
             },
             cancel_all_subs: '1'
           }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)
      assert_equal 'Chargeback created', flash[:notice]
    end
  end
end
