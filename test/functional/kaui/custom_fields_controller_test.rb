# frozen_string_literal: true

require 'test_helper'

module Kaui
  class CustomFieldsControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index
      assert_response 200
    end

    test 'should list custom fields' do
      # Test pagination
      get :pagination, format: :json
      verify_pagination_results!
    end

    test 'should search custom fields' do
      # Test search
      get :pagination, params: { search: { search: 'foo' }, format: :json }
      verify_pagination_results!
    end

    test 'should create custom fields' do
      get :new
      assert_response 200
      assert_not_nil assigns(:custom_field)

      # TODO: https://github.com/killbill/killbill-client-ruby/issues/17
      {
        ACCOUNT: @account.account_id,
        BUNDLE: @bundle.bundle_id,
        SUBSCRIPTION: @bundle_invoice.items.first.subscription_id,
        INVOICE: @bundle_invoice.invoice_id,
        PAYMENT: @payment.payment_id,
        INVALID: 0
      }.each do |object_type, object_id|
        post :create,
             params: {
               custom_field: {
                 object_id:,
                 object_type:,
                 name: SecureRandom.uuid.to_s,
                 value: SecureRandom.uuid.to_s
               }
             }
        assert_redirected_to custom_fields_path
        if object_type.eql?(:INVALID)
          assert_equal 'Object type INVALID or object id do not exist.', flash[:error]
        else
          assert_equal 'Custom field was successfully created', flash[:notice]
        end
      end
    end

    test 'should create custom field account and check if this object exist' do
      get :new
      assert_response 200
      assert_not_nil assigns(:custom_field)

      post :create,
           params: {
             custom_field: {
               object_id: @account.account_id,
               object_type: 'ACCOUNT',
               name: SecureRandom.uuid.to_s,
               value: SecureRandom.uuid.to_s
             }
           }

      assert_redirected_to custom_fields_path
      assert_equal 'Custom field was successfully created', flash[:notice]
    end

    test 'should get error duriing creation of custom field without params supplied' do
      get :check_object_exist, params: { as: :json }
      assert_response 200

      json_response = JSON.parse(response.body)

      assert_equal '431', json_response['status']
      assert_equal 'UUID do not exist in object database.', json_response['message']
    end
  end
end
