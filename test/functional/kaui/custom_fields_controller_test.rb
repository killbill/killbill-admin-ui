require 'test_helper'

class Kaui::CustomFieldsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list custom fields' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search custom fields' do
    # Test search
    get :pagination, :search => {:search => 'foo'}, :format => :json
    verify_pagination_results!
  end

  # test 'should create custom fields' do
  #   get :new
  #   assert_response 200
  #   assert_not_nil assigns(:custom_field)

  #   # TODO https://github.com/killbill/killbill-client-ruby/issues/17
  #   {
  #       :ACCOUNT => @account.account_id,
  #       :BUNDLE => @bundle.bundle_id,
  #       :SUBSCRIPTION => @bundle_invoice.items.first.subscription_id,
  #       :INVOICE => @bundle_invoice.invoice_id,
  #       :PAYMENT => @payment.payment_id,
  #       :INVALID => 0
  #   }.each do |object_type, object_id|
  #     post :create,
  #          :custom_field => {
  #              :object_id => object_id,
  #              :object_type => object_type,
  #              :name => SecureRandom.uuid.to_s,
  #              :value => SecureRandom.uuid.to_s,
  #          }
  #     if object_type.eql?(:INVALID)
  #       assert_response :success
  #       assert_equal 'Invalid object type INVALID',flash.now[:error]
  #     else
  #       assert_redirected_to custom_fields_path
  #       assert_equal 'Custom field was successfully created', flash[:notice]
  #     end
  #   end
  # end

  test 'should create custom field account and check if this object exist' do
    get :new
    assert_response 200
    assert_not_nil assigns(:custom_field)

    post :create,
         custom_field: {
           object_id: @account.account_id,
           object_type: 'ACCOUNT',
           name: SecureRandom.uuid.to_s,
           value: SecureRandom.uuid.to_s
         }

    assert_redirected_to custom_fields_path
    assert_equal 'Custom field was successfully created', flash[:notice]
  end


  # test 'should get error duriing creation of custom field without params supplied' do

  #   get :check_object_exist, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal "431", json_response["status"]
  #   assert_equal "UUID do not exist in object database.", json_response["message"]

  # end

  # test 'should get confirmation that custom field with object type ACCOUNT exist in database' do

  #   get :new
  #   assert_response 200
  #   assert_not_nil assigns(:custom_field)

  #   post :create,
  #        custom_field: {
  #          object_id: @account.account_id,
  #          object_type: 'ACCOUNT',
  #          name: SecureRandom.uuid.to_s,
  #          value: SecureRandom.uuid.to_s
  #        }

  #   assert_response 302
  #   assert_equal 'Custom field was successfully created', flash[:notice]


  #   get :check_object_exist, :uuid => @account.account_id, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal "200", json_response["status"]
  #   assert_equal "UUID do exist in ACCOUNT object database.", json_response["message"]

  # end

  # test 'should get confirmation that custom field with object type INVOICE exist in database' do
  #   invoice_id = create_charge(@account, @tenant).invoice_id

  #   get :check_object_exist, uuid: invoice_id, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal '200', json_response['status']
  #   assert_equal 'UUID do exist in INVOICE object database.', json_response['message']
  # end

  # test 'should get confirmation that custom field with object type INVOICE ITEMS exist in database' do
  #   invoice_item = create_charge(@account, @tenant).invoice_item_id

  #   get :check_object_exist, uuid: invoice_item, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal '200', json_response['status']
  #   assert_equal 'UUID do exist in INVOICE ITEMS object database.', json_response['message']
  # end

  # test 'should get confirmation that custom field with object type PAYMENT exist in database' do
  #   _payment = @payment

  #   get :check_object_exist, uuid: _payment.payment_id, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal '200', json_response['status']
  #   assert_equal 'UUID do exist in PAYMENT object database.', json_response['message']
  # end

  # test 'should get confirmation that custom field with object type BUNDLE exist in database' do
  #   _bundle = @bundle

  #   get :check_object_exist, uuid: _bundle.bundle_id, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal '200', json_response['status']
  #   assert_equal 'UUID do exist in BUNDLE object database.', json_response['message']
  # end

  # test 'should get confirmation that custom field with object type SUBSCRIPTION exist in database' do
  #   _bundle = @bundle
  #   _subscription = _bundle.subscriptions.first


  #   get :check_object_exist, uuid: _subscription.subscription_id, as: :json
  #   assert_response 200

  #   json_response = JSON.parse(response.body)

  #   assert_equal '200', json_response['status']
  #   assert_equal 'UUID do exist in SUBSCRIPTION object database.', json_response['message']
  # end



end
