require 'test_helper'

class Kaui::HomeControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should understand account search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    # search defaults using a UUID
    get :search, :q => @account.account_id
    assert_redirected_to account_path(@account.account_id)

    # search defaults using a String
    get :search, :q => @account.name
    assert_redirected_to accounts_path(:fast => 0, :q => @account.name)

    # search by ID
    get :search, :q => query_builder('ACCOUNT',@account.account_id, 'ID')
    assert_redirected_to account_path(@account.account_id)

    # search by ID and fails
    get :search, :q => query_builder('ACCOUNT',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY
    get :search, :q => query_builder('ACCOUNT',@account.external_key, 'EXTERNAL_KEY')
    assert_redirected_to account_path(@account.account_id)

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('ACCOUNT',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('ACCOUNT',@account.name, nil, '1')
    assert_redirected_to account_path(@account.account_id)

    # search by BLANK
    get :search, :q => query_builder('ACCOUNT',@account.name)
    assert_redirected_to accounts_path(:fast => 0, :q => @account.name)

    # search by BLANK and fails
    get :search, :q => query_builder('ACCOUNT',dummy_uuid)
    assert_redirected_to home_path
    assert_equal "No account matches \"#{dummy_uuid}\"", flash[:error]
  end

  test 'should understand invoice search queries' do
    # search by ID
    get :search, :q => query_builder('INVOICE',@invoice_item.invoice_id, 'ID')
    assert_redirected_to account_invoice_path(@invoice_item.account_id, @invoice_item.invoice_id)

    # search by ID and fails
    get :search, :q => query_builder('INVOICE','112', 'ID')
    assert_redirected_to home_path
    assert_equal "No invoice matches \"112\"", flash[:error]

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('INVOICE','112', 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "\"INVOICE\": Search by \"EXTERNAL KEY\" is not supported.", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('INVOICE',@bundle_invoice.invoice_number, nil, '1')
    assert_redirected_to account_invoice_path(@bundle_invoice.account_id, @bundle_invoice.invoice_id)

    # search by BLANK
    get :search, :q => query_builder('INVOICE',@bundle_invoice.invoice_number)
    assert_redirected_to account_invoices_path(:account_id => @bundle_invoice.account_id, :q => @bundle_invoice.invoice_number, :fast => '0')

    # search by BLANK and fails
    get :search, :q => query_builder('INVOICE','112')
    assert_redirected_to home_path
    assert_equal "No invoice matches \"112\"", flash[:error]
  end

  test 'should understand payment search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    # search by ID
    get :search, :q => query_builder('PAYMENT',@payment.payment_id, 'ID')
    assert_redirected_to account_payment_path(@payment.account_id,@payment.payment_id)

    # search by ID and fails
    get :search, :q => query_builder('PAYMENT',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No payment matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY
    get :search, :q => query_builder('PAYMENT',@payment.payment_external_key, 'EXTERNAL_KEY')
    assert_redirected_to account_payment_path(@payment.account_id,@payment.payment_id)

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('PAYMENT',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "No payment matches \"#{dummy_uuid}\"", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('PAYMENT','SUCCESS', nil, '1')
    assert_redirected_to account_payment_path(@payment.account_id,@payment.payment_id)

    # search by BLANK
    get :search, :q => query_builder('PAYMENT','SUCCESS')
    assert_redirected_to account_payments_path(:account_id => @payment.account_id, :q => 'SUCCESS', :fast => '0')

    # search by BLANK and fails
    get :search, :q => query_builder('PAYMENT','FAILED')
    assert_redirected_to home_path
    assert_equal "No payment matches \"FAILED\"", flash[:error]
  end

  test 'should understand transaction search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    # search by ID
    get :search, :q => query_builder('TRANSACTION',@payment.transactions[0].transaction_id, 'ID')
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

    # search by ID and fails
    get :search, :q => query_builder('TRANSACTION',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No transaction matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('TRANSACTION',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "\"TRANSACTION\": Search by \"EXTERNAL KEY\" is not supported.", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('TRANSACTION',@payment.transactions[0].transaction_id, nil, '1')
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

    # search by BLANK
    get :search, :q => query_builder('TRANSACTION',@payment.transactions[0].transaction_id)
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

    # search by BLANK and fails
    get :search, :q => query_builder('TRANSACTION','112')
    assert_redirected_to home_path
    assert_equal "No transaction matches \"112\"", flash[:error]
  end

  test 'should understand bundle search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    # search by ID
    get :search, :q => query_builder('BUNDLE',@bundle.bundle_id, 'ID')
    assert_redirected_to account_bundles_path(@bundle.account_id)

    # search by ID and fails
    get :search, :q => query_builder('BUNDLE',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY
    get :search, :q => query_builder('BUNDLE',@bundle.external_key, 'EXTERNAL_KEY')
    assert_redirected_to account_bundles_path(@bundle.account_id)

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('BUNDLE',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('BUNDLE',@bundle.account_id, nil, '1')
    assert_redirected_to account_bundles_path(@bundle.account_id)

    # search by BLANK
    get :search, :q => query_builder('BUNDLE',@bundle.account_id)
    assert_redirected_to account_bundles_path(@bundle.account_id)

    # search by BLANK and fails
    get :search, :q => query_builder('BUNDLE',dummy_uuid)
    assert_redirected_to home_path
    assert_equal "No bundle matches \"#{dummy_uuid}\"", flash[:error]
  end

  test 'should understand credit search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    credit = create_credit
    # search by ID
    get :search, :q => query_builder('CREDIT',credit.credit_id, 'ID')
    assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

    # search by ID and fails
    get :search, :q => query_builder('CREDIT',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No credit matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('CREDIT',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "\"CREDIT\": Search by \"EXTERNAL KEY\" is not supported.", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('CREDIT',credit.credit_id, nil, '1')
    assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

    # search by BLANK
    get :search, :q => query_builder('CREDIT',credit.credit_id)
    assert_redirected_to account_invoice_path(credit.account_id, credit.invoice_id)

    # search by BLANK and fails
    get :search, :q => query_builder('CREDIT',dummy_uuid)
    assert_redirected_to home_path
    assert_equal "No credit matches \"#{dummy_uuid}\"", flash[:error]
  end

  test 'should understand custom field search queries' do
    dummy_uuid = SecureRandom.uuid.to_s
    custom_field = create_custom_field
    # search by ID
    get :search, :q => query_builder('CUSTOM_FIELD',custom_field.custom_field_id, 'ID')
    assert_redirected_to custom_fields_path(:q => custom_field.custom_field_id, :fast => '0')

    # search by ID and fails
    get :search, :q => query_builder('CUSTOM_FIELD',dummy_uuid, 'ID')
    assert_redirected_to home_path
    assert_equal "No custom field matches \"#{dummy_uuid}\"", flash[:error]

    # search by EXTERNAL_KEY and fails
    get :search, :q => query_builder('CUSTOM_FIELD',dummy_uuid, 'EXTERNAL_KEY')
    assert_redirected_to home_path
    assert_equal "\"CUSTOM FIELD\": Search by \"EXTERNAL KEY\" is not supported.", flash[:error]

    # search by BLANK only first
    get :search, :q => query_builder('CUSTOM_FIELD',credit.credit_id, nil, '1')
    assert_redirected_to custom_fields_path(:q => custom_field.custom_field_id, :fast => '1')

    # search by BLANK
    get :search, :q => query_builder('CUSTOM_FIELD',credit.credit_id)
    assert_redirected_to custom_fields_path(:q => custom_field.custom_field_id, :fast => '0')

    # search by BLANK and fails
    get :search, :q => query_builder('CUSTOM_FIELD',dummy_uuid)
    assert_redirected_to home_path
    assert_equal "No custom field matches \"#{dummy_uuid}\"", flash[:error]
  end

  private

  def query_builder(object_type, search_for, search_by = nil, fast = nil)
    "FIND:#{object_type} #{(search_by.nil? ? '' : "BY:#{search_by}")} FOR:#{search_for} #{(fast.nil? ? '' : "ONLY_FIRST:#{fast}")}"
  end

  def create_credit
    credit = KillBillClient::Model::Credit.new(:invoice_id => nil, :account_id => @account.account_id, :credit_amount => 23.22)
    credit = credit.create(true, 'kaui', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    credit
  end

  def create_custom_field
    custom_field = Kaui::CustomField.new({ object_id: @account.account_id,
                                             objectType: 'ACCOUNT',
                                             name: 'test',
                                             value: 'test' })
    @account.add_custom_field(custom_field, nil, nil, nil, build_options(@tenant, USERNAME, PASSWORD))
  end
end
