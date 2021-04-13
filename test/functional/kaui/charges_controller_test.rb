require 'test_helper'

class Kaui::ChargesControllerTest < Kaui::FunctionalTestHelper

  test 'should handle Kill Bill errors in new screen' do
    invoice_id = SecureRandom.uuid.to_s
    get :new, :account_id => @account.account_id, :invoice_id => invoice_id
    assert_redirected_to account_path(@account.account_id)
    assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
  end

  test 'should get new for new invoice' do
    get :new, :account_id => @account.account_id
    assert_response 200
  end

  test 'should get new for existing invoice' do
    get :new, :account_id => @account.account_id, :invoice_id => @invoice_item.invoice_id
    assert_response 200
  end

  test 'should handle Kill Bill errors during creation' do
    invoice_id = SecureRandom.uuid.to_s
    post :create,
         :account_id => @account.account_id,
         :invoice_item => {
             :invoice_id => invoice_id,
             :amount => 5.34,
             :currency => 'USD',
             :description => SecureRandom.uuid
         }
    assert_redirected_to account_path(@account.account_id)
    assert_equal "Error while communicating with the Kill Bill server: Object id=#{invoice_id} type=INVOICE doesn't exist!", flash[:error]
  end

  test 'should create charge' do
    post :create,
         :account_id => @account.account_id,
         :invoice_item => {
             :amount => 5.34,
             :currency => 'USD',
             :description => SecureRandom.uuid
         }
    assert_response :redirect
    assert_equal 'Charge was successfully created', flash[:notice]
  end

  test 'should create charge for existing invoice' do
    post :create,
         :account_id => @account.account_id,
         :invoice_item => {
             :invoice_id => @invoice_item.invoice_id,
             :amount => 5.34,
             :currency => 'USD',
             :description => SecureRandom.uuid
         }
    assert_redirected_to account_invoice_path(@account.account_id, @invoice_item.invoice_id)
    assert_equal 'Charge was successfully created', flash[:notice]
  end
end
