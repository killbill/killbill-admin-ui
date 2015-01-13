require 'test_helper'

class Kaui::PaymentMethodsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list payment methods' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search payment methods' do
    # Test search
    get :pagination, :sSearch => 'foo', :format => :json
    verify_pagination_results!
  end

  test 'should create payment methods' do
    post :create,
         :payment_method     => {
             :account_id => @account.account_id,
             :is_default => true
         },
         :card_type          => SecureRandom.uuid.to_s,
         :card_holder_name   => SecureRandom.uuid.to_s,
         :expiration_year    => 2020,
         :expiration_month   => 12,
         :credit_card_number => 4111111111111111,
         :address1           => SecureRandom.uuid.to_s,
         :city               => SecureRandom.uuid.to_s,
         :postal_code        => SecureRandom.uuid.to_s,
         :state              => SecureRandom.uuid.to_s,
         :country            => SecureRandom.uuid.to_s
    assert_response 302

    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!(1)
  end

  test 'should delete payment methods' do
    delete :destroy, :id => @payment_method.payment_method_id, :set_auto_pay_off => true
    assert_response 302
  end
end
