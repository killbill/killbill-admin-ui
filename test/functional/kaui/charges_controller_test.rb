require 'test_helper'

class Kaui::ChargesControllerTest < Kaui::FunctionalTestHelper

  test 'should get new for new invoice' do
    get :new, :account_id => @account.account_id
    assert_response 200
  end

  test 'should get new for existing invoice' do
    get :new, :invoice_id => @invoice_item.invoice_id
    assert_response 200
  end

  test 'should create charge' do
    post :create,
         :invoice_item => {
             :account_id  => @account.account_id,
             :amount      => 5.34,
             :currency    => 'USD',
             :description => SecureRandom.uuid
         }
    assert_redirected_to invoice_path(assigns(:charge).invoice_id)
    assert_equal 'Charge was successfully created', flash[:notice]
  end

  test 'should create charge for existing invoice' do
    post :create,
         :invoice_item => {
             :account_id  => @account.account_id,
             :invoice_id  => @invoice_item.invoice_id,
             :amount      => 5.34,
             :currency    => 'USD',
             :description => SecureRandom.uuid
         }
    assert_redirected_to invoice_path(assigns(:charge).invoice_id)
    assert_equal 'Charge was successfully created', flash[:notice]
  end
end
