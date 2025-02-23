# frozen_string_literal: true

require 'test_helper'

module Kaui
  class PaymentsControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index, params: { account_id: @invoice_item.account_id }
      assert_response 200
    end

    test 'should list payments' do
      # Test pagination
      get :pagination, params: { format: :json }
      verify_pagination_results!
    end

    test 'should search payments' do
      # Test search
      get :pagination, params: { search: { value: 'PENDING' }, format: :json }
      verify_pagination_results!
    end

    test 'should create payments' do
      # Verify we can pre-populate the payment
      get :new, params: { account_id: @invoice_item.account_id, invoice_id: @invoice_item.invoice_id }
      assert_response 200
      assert_not_nil assigns(:payment)

      # Create the payment
      post :create, params: { account_id: @invoice_item.account_id, invoice_payment: { account_id: @invoice_item.account_id, target_invoice_id: @invoice_item.invoice_id, purchased_amount: 10 }, external: 1 }
      assert_response 302

      # Test pagination
      get :pagination, params: { format: :json }
      verify_pagination_results!(1)
    end

    test 'should expose restful endpoint' do
      get :restful_show, params: { id: @payment.payment_id }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # Search by external_key
      get :restful_show, params: { id: @payment.payment_external_key }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)
    end

    test 'should cancel scheduled payment' do
      delete :cancel_scheduled_payment, params: { id: @payment.payment_id, account_id: @payment.account_id }
      assert_match(/Error deleting payment attempt retry:/, flash[:error])
      expected_response_path = "/accounts/#{@payment.account_id}"
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

      delete :cancel_scheduled_payment,
             params: {
               id: @payment.payment_id, account_id: @payment.account_id,
               transaction_external_key: @payment.transactions[0].transaction_external_key
             }
      assert_equal 'Payment attempt retry successfully deleted', flash[:notice]
      expected_response_path = "/accounts/#{@payment.account_id}/payments/#{@payment.payment_id}"
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
    end

    test 'should download payments data' do
      start_date = Date.today.strftime('%Y-%m-%d')
      end_date = Date.today.strftime('%Y-%m-%d')
      columns = %w[payment_id auth currency capture purchase refund credit]

      get :download, params: { startDate: start_date, endDate: end_date, allFieldsChecked: 'false', columnsString: columns.join(',') }
      assert_response :success
      assert_equal 'text/csv', @response.header['Content-Type']
      assert_includes @response.header['Content-Disposition'], "filename=\"payments-#{Date.today}.csv\""
      assert_includes @response.body, @payment.payment_id

      csv = CSV.parse(@response.body, headers: true)
      assert_equal %w[payment_id auth_amount currency captured_amount purchased_amount refunded_amount credited_amount], csv.headers
    end
  end
end
