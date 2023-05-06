# frozen_string_literal: true

require 'test_helper'

module Kaui
  class PaymentMethodsControllerTest < Kaui::FunctionalTestHelper
    test 'should get new' do
      get :new, params: { account_id: @account2.account_id }
      assert_response :success
      assert_equal extract_value_from_input_field('payment_method_plugin_name'), '__EXTERNAL_PAYMENT__'
      assert_equal extract_value_from_input_field('payment_method_account_id'), @account2.account_id
    end

    test 'should get show' do
      get :show, params: { id: @payment_method.payment_method_id }
      assert_response :redirect
      assert_redirected_to account_path(@payment_method.account_id)
    end

    test 'should create payment methods' do
      post :create,
           params: {
             payment_method: {
               # Note that @account already has an external payment method
               account_id: @account2.account_id,
               is_default: true
             },
             card_type: SecureRandom.uuid.to_s,
             card_holder_name: SecureRandom.uuid.to_s,
             expiration_year: 2020,
             expiration_month: 12,
             credit_card_number: 4_111_111_111_111_111,
             address1: SecureRandom.uuid.to_s,
             city: SecureRandom.uuid.to_s,
             postal_code: SecureRandom.uuid.to_s,
             state: SecureRandom.uuid.to_s,
             country: SecureRandom.uuid.to_s
           }
      assert_response 302
      assert_equal 'Payment method was successfully created', flash[:notice]
    end

    test 'should delete payment methods' do
      delete :destroy, params: { id: @payment_method.payment_method_id, set_auto_pay_off: true }
      assert_response 302
      assert_equal "Payment method #{@payment_method.payment_method_id} successfully deleted", flash[:notice]
    end

    test 'should validate external key if found' do
      get :validate_external_key, params: { external_key: 'foo' }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], false

      get :validate_external_key, params: { external_key: @payment_method.external_key }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], true
    end

    test 'should get new payment method with external key, fail when duplicated external key' do
      new_account = create_account(@tenant)

      new_acc = new_account.account_id
      post :create,
           params: {
             payment_method: {
               # Note that @account already has an external payment method
               account_id: new_acc,
               is_default: true,
               plugin_name: '__EXTERNAL_PAYMENT__',
               external_key: 'paypal'

             },
             card_type: SecureRandom.uuid.to_s,
             card_holder_name: SecureRandom.uuid.to_s,
             expiration_year: 2020,
             expiration_month: 12,
             credit_card_number: 4_111_111_111_111_111,
             address1: SecureRandom.uuid.to_s,
             city: SecureRandom.uuid.to_s,
             postal_code: SecureRandom.uuid.to_s,
             state: SecureRandom.uuid.to_s,
             country: SecureRandom.uuid.to_s
           }

      assert_response 302
      assert_equal 'Payment method was successfully created', flash[:notice]

      post :create,
           params: {
             payment_method: {
               # Note that @account already has an external payment method
               account_id: new_acc,
               is_default: true,
               plugin_name: '__EXTERNAL_PAYMENT__',
               external_key: 'paypal'

             },
             card_type: SecureRandom.uuid.to_s,
             card_holder_name: SecureRandom.uuid.to_s,
             expiration_year: 2020,
             expiration_month: 12,
             credit_card_number: 4_111_111_111_111_111,
             address1: SecureRandom.uuid.to_s,
             city: SecureRandom.uuid.to_s,
             postal_code: SecureRandom.uuid.to_s,
             state: SecureRandom.uuid.to_s,
             country: SecureRandom.uuid.to_s
           }

      assert_response 200
      assert_equal "Error while creating payment method: External payment method already exists for account #{new_acc}", flash[:error]
    end
  end
end
