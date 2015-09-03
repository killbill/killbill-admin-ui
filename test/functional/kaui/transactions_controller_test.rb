require 'test_helper'

class Kaui::TransactionsControllerTest < Kaui::FunctionalTestHelper

  test 'should get new' do
    get :new,
        :account_id        => @account.account_id,
        :payment_method_id => @payment_method.payment_method_id,
        :payment_id        => @payment.payment_id,
        :amount            => 12,
        :currency          => 'USD',
        :transaction_type  => 'CAPTURE'
    assert_response 200
    assert_not_nil assigns(:account_id)
    assert_not_nil assigns(:payment_method_id)
    assert_not_nil assigns(:transaction)
  end

  test 'should create new transaction' do
    post :create,
         :account_id        => @account.account_id,
         :payment_method_id => @payment_method.payment_method_id,
         :transaction       => {
             :payment_external_key => SecureRandom.uuid,
             :amount               => 12,
             :currency             => 'USD',
             :transaction_type     => 'AUTHORIZE'
         }
    assert_response :redirect
    assert_equal 'Transaction successfully created', flash[:notice]
  end
end
