# frozen_string_literal: true

require 'test_helper'

module Kaui
  class HomeControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index
      assert_response :success
    end

    test 'should understand account search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      # search defaults using a UUID
      get :search, params: { q: @account.account_id }
      assert_redirected_to account_path(@account.account_id)

      # search defaults using a String
      get :search, params: { q: @account.name }
      assert_redirected_to accounts_path(fast: 0, q: @account.name)

      # search by ID
      get :search, params: { q: query_builder('ACCOUNT', @account.account_id, 'ID') }
      assert_redirected_to account_path(@account.account_id)

      # search by ID and fails
      get :search, params: { q: query_builder('ACCOUNT', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY
      get :search, params: { q: query_builder('ACCOUNT', @account.external_key, 'EXTERNAL_KEY') }
      assert_redirected_to account_path(@account.account_id)

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('ACCOUNT', dummy_uuid, 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('ACCOUNT', @account.name, nil, '1') }
      assert_redirected_to account_path(@account.account_id)

      # search by BLANK
      get :search, params: { q: query_builder('ACCOUNT', @account.name) }
      assert_redirected_to accounts_path(fast: 0, q: @account.name)

      # search by BLANK and fails
      get :search, params: { q: query_builder('ACCOUNT', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand invoice search queries' do
      # search by ID
      get :search, params: { q: query_builder('INVOICE', @invoice_item.invoice_id, 'ID') }
      assert_redirected_to account_invoice_path(@invoice_item.account_id, @invoice_item.invoice_id)

      # search by ID and fails
      get :search, params: { q: query_builder('INVOICE', '112', 'ID') }
      assert_redirected_to home_path
      assert_equal 'No invoice matches "112"', flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('INVOICE', '112', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"INVOICE": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('INVOICE', @bundle_invoice.invoice_number, nil, '1') }
      assert_redirected_to account_invoice_path(@bundle_invoice.account_id, @bundle_invoice.invoice_id)

      # search by BLANK only first (invoice item)
      get :search, params: { q: query_builder('INVOICE', @bundle_invoice.items[0].invoice_item_id, nil, '1') }
      assert_redirected_to account_invoice_path(@bundle_invoice.account_id, @bundle_invoice.invoice_id)

      # search by BLANK
      get :search, params: { q: query_builder('INVOICE', @bundle_invoice.invoice_number) }
      assert_redirected_to account_invoices_path(account_id: @bundle_invoice.account_id, q: @bundle_invoice.invoice_number, fast: '0')

      # search by BLANK and fails
      get :search, params: { q: query_builder('INVOICE', '112') }
      assert_redirected_to home_path
      assert_equal 'No invoice matches "112"', flash[:error]
    end

    test 'should understand payment search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      # search by ID
      get :search, params: { q: query_builder('PAYMENT', @payment.payment_id, 'ID') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by ID and fails
      get :search, params: { q: query_builder('PAYMENT', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No payment matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY
      get :search, params: { q: query_builder('PAYMENT', @payment.payment_external_key, 'EXTERNAL_KEY') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('PAYMENT', dummy_uuid, 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal "No payment matches \"#{dummy_uuid}\"", flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('PAYMENT', 'SUCCESS', nil, '1') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by BLANK
      get :search, params: { q: query_builder('PAYMENT', 'SUCCESS') }
      assert_redirected_to account_payments_path(account_id: @payment.account_id, q: 'SUCCESS', fast: '0')

      # search by BLANK and fails
      get :search, params: { q: query_builder('PAYMENT', 'FAILED') }
      assert_redirected_to home_path
      assert_equal 'No payment matches "FAILED"', flash[:error]
    end

    test 'should understand transaction search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      # search by ID
      get :search, params: { q: query_builder('TRANSACTION', @payment.transactions[0].transaction_id, 'ID') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by ID and fails
      get :search, params: { q: query_builder('TRANSACTION', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No transaction matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY
      get :search, params: { q: query_builder('TRANSACTION', @payment.transactions[0].transaction_external_key, 'EXTERNAL_KEY') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('TRANSACTION', dummy_uuid, 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal "No transaction matches \"#{dummy_uuid}\"", flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('TRANSACTION', @payment.transactions[0].transaction_id, nil, '1') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by BLANK
      get :search, params: { q: query_builder('TRANSACTION', @payment.transactions[0].transaction_id) }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by BLANK and fails
      get :search, params: { q: query_builder('TRANSACTION', '112') }
      assert_redirected_to home_path
      assert_equal 'No transaction matches "112"', flash[:error]
    end

    test 'should understand bundle search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      # search by ID
      get :search, params: { q: query_builder('BUNDLE', @bundle.bundle_id, 'ID') }
      assert_redirected_to account_bundles_path(@bundle.account_id)

      # search by ID and fails
      get :search, params: { q: query_builder('BUNDLE', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY
      get :search, params: { q: query_builder('BUNDLE', @bundle.external_key, 'EXTERNAL_KEY') }
      assert_redirected_to account_bundles_path(@bundle.account_id)

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('BUNDLE', dummy_uuid, 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('BUNDLE', @bundle.account_id, nil, '1') }
      assert_redirected_to account_bundles_path(@bundle.account_id)

      # search by BLANK
      get :search, params: { q: query_builder('BUNDLE', @bundle.account_id) }
      assert_redirected_to account_bundles_path(@bundle.account_id)

      # search by BLANK and fails
      get :search, params: { q: query_builder('BUNDLE', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand credit search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      credit = create_credit
      # search by ID
      get :search, params: { q: query_builder('CREDIT', credit.invoice_item_id, 'ID') }
      assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

      # search by ID and fails
      get :search, params: { q: query_builder('CREDIT', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No credit matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('CREDIT', dummy_uuid, 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"CREDIT": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('CREDIT', credit.invoice_item_id, nil, '1') }
      assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

      # search by BLANK
      get :search, params: { q: query_builder('CREDIT', credit.invoice_item_id) }
      assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

      # search by BLANK and fails
      get :search, params: { q: query_builder('CREDIT', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No credit matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand custom field search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      custom_field = create_custom_field
      # search by ID
      get :search, params: { q: query_builder('CUSTOM_FIELD', custom_field[0].custom_field_id, 'ID') }
      assert_redirected_to custom_fields_path(q: custom_field[0].custom_field_id, fast: '0')

      # search by ID and fails
      get :search, params: { q: query_builder('CUSTOM_FIELD', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No custom field matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('CUSTOM_FIELD', 'test', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"CUSTOM FIELD": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('CUSTOM_FIELD', 'test', nil, '1') }
      assert_redirected_to custom_fields_path(q: 'test', fast: '1')

      # search by BLANK
      get :search, params: { q: query_builder('CUSTOM_FIELD', 'test') }
      assert_redirected_to custom_fields_path(q: 'test', fast: '0')

      # search by BLANK and fails
      get :search, params: { q: query_builder('CUSTOM_FIELD', 'test_uui') }
      assert_redirected_to home_path
      assert_equal 'No custom field matches "test_uui"', flash[:error]
    end

    test 'should understand invoice payment search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      # search by ID
      get :search, params: { q: query_builder('INVOICE_PAYMENT', @payment.payment_id, 'ID') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by ID and fails
      get :search, params: { q: query_builder('INVOICE_PAYMENT', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No invoice payment matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('INVOICE_PAYMENT', 'test', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"INVOICE PAYMENT": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('INVOICE_PAYMENT', @payment.payment_id, nil, '1') }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by BLANK
      get :search, params: { q: query_builder('INVOICE_PAYMENT', @payment.payment_id) }
      assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

      # search by BLANK and fails
      get :search, params: { q: query_builder('INVOICE_PAYMENT', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No invoice payment matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand subscription search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      subscription = @bundle.subscriptions[0]
      # search by ID
      get :search, params: { q: query_builder('SUBSCRIPTION', subscription.subscription_id, 'ID') }
      assert_redirected_to account_bundles_path(subscription.account_id)

      # search by ID and fails
      get :search, params: { q: query_builder('SUBSCRIPTION', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No subscription matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('SUBSCRIPTION', 'test', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"SUBSCRIPTION": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('SUBSCRIPTION', subscription.subscription_id, nil, '1') }
      assert_redirected_to account_bundles_path(subscription.account_id)

      # search by BLANK
      get :search, params: { q: query_builder('SUBSCRIPTION', subscription.subscription_id) }
      assert_redirected_to account_bundles_path(subscription.account_id)

      # search by BLANK and fails
      get :search, params: { q: query_builder('SUBSCRIPTION', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No subscription matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand tag search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      tag = create_tag
      # search by ID
      get :search, params: { q: query_builder('TAG', tag[0].tag_id, 'ID') }
      assert_redirected_to tags_path(q: tag[0].tag_id, fast: '0')

      # search by ID and fails
      get :search, params: { q: query_builder('TAG', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No tag matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('TAG', 'test', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"TAG": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('TAG', 'account', nil, '1') }
      assert_redirected_to tags_path(q: 'account', fast: '1')

      # search by BLANK
      get :search, params: { q: query_builder('TAG', 'account') }
      assert_redirected_to tags_path(q: 'account', fast: '0')

      # search by BLANK and fails
      get :search, params: { q: query_builder('TAG', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No tag matches \"#{dummy_uuid}\"", flash[:error]
    end

    test 'should understand tag definition search queries' do
      dummy_uuid = SecureRandom.uuid.to_s
      tag_definition = create_account_tag_definition
      # search by ID
      get :search, params: { q: query_builder('TAG_DEFINITION', tag_definition.id, 'ID') }
      assert_redirected_to tag_definitions_path(q: tag_definition.id, fast: '0')

      # search by ID and fails
      get :search, params: { q: query_builder('TAG_DEFINITION', dummy_uuid, 'ID') }
      assert_redirected_to home_path
      assert_equal "No tag definition matches \"#{dummy_uuid}\"", flash[:error]

      # search by EXTERNAL_KEY and fails
      get :search, params: { q: query_builder('TAG_DEFINITION', 'test', 'EXTERNAL_KEY') }
      assert_redirected_to home_path
      assert_equal '"TAG DEFINITION": Search by "EXTERNAL KEY" is not supported.', flash[:error]

      # search by BLANK only first
      get :search, params: { q: query_builder('TAG_DEFINITION', 'account', nil, '1') }
      assert_redirected_to tag_definitions_path(q: 'account', fast: '1')

      # search by BLANK
      get :search, params: { q: query_builder('TAG_DEFINITION', 'account') }
      assert_redirected_to tag_definitions_path(q: 'account', fast: '0')

      # search by BLANK and fails
      get :search, params: { q: query_builder('TAG_DEFINITION', dummy_uuid) }
      assert_redirected_to home_path
      assert_equal "No tag definition matches \"#{dummy_uuid}\"", flash[:error]
    end

    private

    def query_builder(object_type, search_for, search_by = nil, fast = nil)
      "FIND:#{object_type} #{search_by.nil? ? '' : "BY:#{search_by}"} FOR:#{search_for} #{fast.nil? ? '' : "ONLY_FIRST:#{fast}"}"
    end

    def create_credit
      credit = KillBillClient::Model::Credit.new(invoice_id: nil, account_id: @account.account_id, amount: 2.22)
      credit = credit.create(true, 'kaui search test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
      credit.first
    end

    def create_custom_field
      custom_field = Kaui::CustomField.new({ object_id: @account.account_id,
                                             objectType: 'ACCOUNT',
                                             name: 'test',
                                             value: 'test' })
      @account.add_custom_field(custom_field, 'kaui search test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    end

    def create_account_tag_definition(name = 'account', description = 'i am an account')
      tag_definition = Kaui::TagDefinition.new({ is_control_tag: false,
                                                 name:,
                                                 description:,
                                                 applicable_object_types: ['ACCOUNT'] })

      tag_definition.create('kaui search test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    end

    def create_tag
      tag_definition = create_account_tag_definition
      tags = [tag_definition.id]
      Kaui::Tag.set_for_account(@account.account_id, tags, 'kaui search test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    end
  end
end
