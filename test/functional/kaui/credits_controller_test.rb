require 'test_helper'

class Kaui::CreditsControllerTest < Kaui::FunctionalTestHelper

  test 'should get new for new invoice' do
    get :new, :account_id => @account.account_id
    assert_response 200
  end

  test 'should get new for existing invoice' do
    get :new, :invoice_id => @invoice_item.invoice_id
    assert_response 200
  end

  test 'should create credit' do
    post :create,
         :credit => {
             :account_id    => @account.account_id,
             :credit_amount => 5.34
         }
    assert_redirected_to invoice_path(assigns(:credit).invoice_id)
    assert_equal 'Credit was successfully created', flash[:notice]
  end

  test 'should create credit for existing invoice' do
    post :create,
         :credit => {
             :account_id    => @account.account_id,
             :invoice_id    => @invoice_item.invoice_id,
             :credit_amount => 5.34
         }
    assert_redirected_to invoice_path(assigns(:credit).invoice_id)
    assert_equal 'Credit was successfully created', flash[:notice]
  end
end
