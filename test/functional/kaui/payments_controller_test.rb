require 'test_helper'

class Kaui::PaymentsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list payments' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search payments' do
    # Test search
    get :pagination, :sSearch => 'foo', :format => :json
    verify_pagination_results!
  end

  test 'should create payments' do
    # Verify we can pre-populate the payment
    get :new, :account_id => @invoice_item.account_id, :invoice_id => @invoice_item.invoice_id
    assert_response 200
    assert_not_nil assigns(:payment)

    # Create the payment
    post :create, :invoice_payment => {:account_id => @invoice_item.account_id, :target_invoice_id => @invoice_item.invoice_id, :purchased_amount => 10}, :external => 1
    assert_response 302

    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!(1)
  end
end
