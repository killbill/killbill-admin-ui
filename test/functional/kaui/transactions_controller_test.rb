require 'test_helper'

class Kaui::TransactionsControllerTest < Kaui::FunctionalTestHelper

  test 'should get new' do
    get :new,
        :account_id => @account.account_id,
        :payment_method_id => @payment_method.payment_method_id,
        :payment_id => @payment.payment_id,
        :amount => 12,
        :currency => 'USD',
        :transaction_type => 'CAPTURE'
    assert_response 200
    assert_not_nil assigns(:account_id)
    assert_not_nil assigns(:payment_method_id)
    assert_not_nil assigns(:transaction)
  end

  test 'should create new transaction' do
    payments = []
    %w(AUTHORIZE AUTHORIZE PURCHASE PURCHASE CREDIT).each do |transaction_type|
      post :create,
           :account_id => @account.account_id,
           :payment_method_id => @payment_method.payment_method_id,
           :transaction => {
               :payment_external_key => SecureRandom.uuid,
               :amount => 12,
               :currency => 'USD',
               :transaction_type => transaction_type
           }

      payments << created_payment_id
      assert_redirected_to account_payment_path(@account.account_id, payments[-1])
      assert_equal 'Transaction successfully created', flash[:notice]
    end

    %w(CAPTURE VOID REFUND CHARGEBACK).each do |transaction_type|
      payment_id = payments.shift
      post :create,
           :account_id => @account.account_id,
           :transaction => {
               :payment_id => payment_id,
               :amount => 12,
               :currency => 'USD',
               :transaction_type => transaction_type
           }
      assert_redirected_to account_payment_path(@account.account_id, payment_id)
      assert_equal 'Transaction successfully created', flash[:notice]
    end
  end

  private

  def created_payment_id
    response.header['Location'].split('/')[-1]
  end
end
