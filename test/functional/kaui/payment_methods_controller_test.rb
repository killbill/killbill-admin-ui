require 'test_helper'

class Kaui::PaymentMethodsControllerTest < Kaui::FunctionalTestHelper

  test 'should create payment methods' do
    post :create,
         :payment_method     => {
             # Note that @account already has an external payment method
             :account_id => @account2.account_id,
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
  end

  test 'should delete payment methods' do
    delete :destroy, :id => @payment_method.payment_method_id, :set_auto_pay_off => true
    assert_response 302
  end

  test'should validate external key if found' do
    get :validate_external_key, :external_key => 'foo'
    assert_response :success
    assert_equal JSON[@response.body]['is_found'], false

    get :validate_external_key, :external_key => @payment_method.external_key
    assert_response :success
    assert_equal JSON[@response.body]['is_found'], true
  end
end
