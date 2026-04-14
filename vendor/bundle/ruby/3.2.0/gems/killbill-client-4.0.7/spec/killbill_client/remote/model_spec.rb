require 'spec_helper'

describe KillBillClient::Model do
  before do
    KillBillClient.return_full_stacktraces = true

    KillBillClient.api_key = SecureRandom.uuid.to_s + rand(100).to_s
    KillBillClient.api_secret = KillBillClient.api_key

    tenant = KillBillClient::Model::Tenant.new
    tenant.api_key = KillBillClient.api_key
    tenant.api_secret = KillBillClient.api_secret
    tenant.create(true, 'KillBill Spec test')
  end

  after do
    KillBillClient.return_full_stacktraces = false
  end

  it 'should manipulate accounts', :integration => true  do
    # In case the remote server has lots of data
    search_limit = 100000

    external_key = SecureRandom.uuid.to_s

    account = KillBillClient::Model::Account.new
    account.name = 'KillBillClient'
    account.external_key = external_key
    account.email = 'kill@bill.com'
    account.currency = 'USD'
    account.time_zone = 'UTC'
    account.address1 = '5, ruby road'
    account.address2 = 'Apt 4'
    account.postal_code = 10293
    account.company = 'KillBill, Inc.'
    account.city = 'SnakeCase'
    account.state = 'Awesome'
    account.country = 'LalaLand'
    account.locale = 'fr_FR'
    expect(account.account_id).to be_nil

    # Create and verify the account
    account = account.create('KillBill Spec test')
    expect(account.external_key).to eq(external_key)
    expect(account.account_id).not_to be_nil
    account_id = account.account_id

    # Try to retrieve it
    account = KillBillClient::Model::Account.find_by_id account.account_id
    expect(account.external_key).to eq(external_key)
    expect(account.payment_method_id).to be_nil

    # Update account
    account.name = 'Kill Bill Client'
    account.update(false, 'KillBill Spec test')

    # Try to retrieve it
    account = KillBillClient::Model::Account.find_by_external_key external_key
    expect(account.account_id).to eq(account_id)
    expect(account.payment_method_id).to be_nil

    # Try to retrieve it (bis repetita placent)
    accounts = KillBillClient::Model::Account.find_in_batches(0, search_limit)
    # Can't test equality if the remote server has extra data
    expect(accounts.pagination_total_nb_records).to be >= 1
    expect(accounts.pagination_max_nb_records).to be >= 1
    expect(accounts.size).to be >= 1
    # If the remote server has lots of data, we need to page through the results (good test!)
    found = nil
    accounts.each_in_batches do |account|
      found = account if account.external_key == external_key
      break unless found.nil?
    end
    expect(found).not_to be_nil

    # Try to retrieve it via the search API
    accounts = KillBillClient::Model::Account.find_in_batches_by_search_key(account.name, 0, search_limit)
    # Can't test equality if the remote server has extra data
    expect(accounts.pagination_total_nb_records).to be >= 1
    expect(accounts.pagination_max_nb_records).to be >= 1
    expect(accounts.size).to be >= 1
    # If the remote server has lots of data, we need to page through the results (good test!)
    found = nil
    accounts.each_in_batches do |account|
      found = account if account.external_key == external_key
      break unless found.nil?
    end
    expect(found).not_to be_nil

    # Add/Remove a tag
    expect(account.tags.size).to eq(0)
    account.add_tag('TEST', 'KillBill Spec test')
    tags = account.tags
    expect(tags.size).to eq(1)
    expect(tags.first.tag_definition_name).to eq('TEST')
    account.remove_tag('TEST', 'KillBill Spec test')
    expect(account.tags.size).to eq(0)

    # Add/Remove a custom field
    expect(account.custom_fields.size).to eq(0)
    custom_field = KillBillClient::Model::CustomField.new
    custom_field.name = SecureRandom.uuid.to_s
    custom_field.value = SecureRandom.uuid.to_s
    custom_field_other = KillBillClient::Model::CustomField.new
    custom_field_other.name = SecureRandom.uuid.to_s
    custom_field_other.value = SecureRandom.uuid.to_s
    account.add_custom_field(custom_field, 'KillBill Spec test')
    account.add_custom_field(custom_field_other, 'KillBill Spec test other')
    custom_fields = account.custom_fields
    expect(custom_fields.size).to eq(2)
    expect(custom_fields.first.name).to eq(custom_field.name)
    expect(custom_fields.first.value).to eq(custom_field.value)
    account.remove_custom_field(custom_fields.first.custom_field_id, 'KillBill Spec test')
    expect(account.custom_fields.size).to eq(1)

    # Add a payment method
    pm = KillBillClient::Model::PaymentMethod.new
    pm.account_id = account.account_id
    pm.is_default = true
    pm.plugin_name = KillBillClient::Model::PaymentMethod::EXTERNAL_PAYMENT
    pm.plugin_info = {}
    expect(pm.payment_method_id).to be_nil

    pm = pm.create(true, 'KillBill Spec test')
    expect(pm.payment_method_id).not_to be_nil

    # Try to retrieve it
    pm = KillBillClient::Model::PaymentMethod.find_by_id pm.payment_method_id, true
    expect(pm.account_id).to eq(account.account_id)

    # Try to retrieve it (bis repetita placent)
    pms = KillBillClient::Model::PaymentMethod.find_in_batches(0, search_limit)
    # Can't test equality if the remote server has extra data
    expect(pms.pagination_total_nb_records).to be >= 1
    expect(pms.pagination_max_nb_records).to be >= 1
    expect(pms.size).to be >= 1
    # If the remote server has lots of data, we need to page through the results (good test!)
    found = nil
    pms.each_in_batches do |payment_method|
      found = payment_method if payment_method.payment_method_id == pm.payment_method_id
      break unless found.nil?
    end
    expect(found).not_to be_nil

    account = KillBillClient::Model::Account.find_by_id account.account_id
    expect(account.payment_method_id).to eq(pm.payment_method_id)

    pms = KillBillClient::Model::PaymentMethod.find_all_by_account_id account.account_id
    expect(pms.size).to eq(1)
    expect(pms[0].payment_method_id).to eq(pm.payment_method_id)

    # Check there is no payment associated with that account
    expect(account.payments.size).to eq(0)

    # Add an external charge
    invoice_item = KillBillClient::Model::InvoiceItem.new
    invoice_item.account_id = account.account_id
    invoice_item.currency = account.currency
    invoice_item.amount = 123.98

    invoice_item = invoice_item.create false, true, 'KillBill Spec test'
    invoice = KillBillClient::Model::Invoice.find_by_id invoice_item.invoice_id

    expect(invoice.amount).to eq(123.98)
    expect(invoice.balance).to eq(0)

    invoice.commit 'KillBill Spec test'

    # Add/Remove a invoice item tag
    expect(invoice.tags.size).to eq(0)
    invoice.add_tag('WRITTEN_OFF', 'KillBill Spec test')
    tags = invoice.tags
    expect(tags.size).to eq(1)
    expect(tags.first.tag_definition_name).to eq('WRITTEN_OFF')
    invoice.remove_tag('WRITTEN_OFF', 'KillBill Spec test')
    expect(invoice.tags.size).to eq(0)

    # Add/Remove a invoice item custom field
    expect(invoice_item.custom_fields.size).to eq(0)
    custom_field = KillBillClient::Model::CustomField.new
    custom_field.name = Time.now.to_i.to_s
    custom_field.value = Time.now.to_i.to_s
    invoice_item.add_custom_field(custom_field, 'KillBill Spec test')
    custom_fields = invoice_item.custom_fields
    expect(custom_fields.size).to eq(1)
    expect(custom_fields.first.name).to eq(custom_field.name)
    expect(custom_fields.first.value).to eq(custom_field.value)
    invoice_item.remove_custom_field(custom_fields.first.custom_field_id, 'KillBill Spec test')
    expect(invoice_item.custom_fields.size).to eq(0)

    # Check the account balance (need to wait a bit for the payment to happen)
    begin
      retries ||= 0
      sleep(1) if retries > 0
      account = KillBillClient::Model::Account.find_by_id account.account_id, true
      expect(account.account_balance).to eq(0)
    rescue Exception => e
      if (retries += 1) < 15
        retry
      else
        raise e
      end
    end

    KillBillClient::Model::PaymentMethod.destroy(pm.payment_method_id, true, true, 'KillBill Spec test')

    account = KillBillClient::Model::Account.find_by_id account.account_id
    expect(account.payment_method_id).to be_nil

    # Get its timeline
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id

    expect(timeline.account.external_key).to eq(external_key)
    expect(timeline.account.account_id).not_to be_nil

    expect(timeline.invoices).to be_a_kind_of Array
    expect(timeline.invoices).not_to be_empty
    expect(timeline.payments).to be_a_kind_of Array
    expect(timeline.bundles).to be_a_kind_of Array

    # Let's find the invoice by two methods
    invoice = timeline.invoices.first
    invoice_id = invoice.invoice_id
    invoice_number = invoice.invoice_number

    invoice_with_id = KillBillClient::Model::Invoice.find_by_id invoice_id
    invoice_with_number = KillBillClient::Model::Invoice.find_by_number invoice_number

    expect(invoice_with_id.invoice_id).to eq(invoice_with_number.invoice_id)
    expect(invoice_with_id.invoice_number).to eq(invoice_with_number.invoice_number)

    # Create an external payment for each unpaid invoice
    invoice_payment = KillBillClient::Model::InvoicePayment.new
    invoice_payment.account_id = account.account_id
    invoice_payment.bulk_create true, nil, nil, 'KillBill Spec test'

    # Try to retrieve it
    payments = KillBillClient::Model::Payment.find_in_batches(0, search_limit)
    # Can't test equality if the remote server has extra data
    expect(payments.pagination_total_nb_records).to be >= 1
    expect(payments.pagination_max_nb_records).to be >= 1
    expect(payments.size).to be >= 1
    # If the remote server has lots of data, we need to page through the results (good test!)
    found = nil
    payments.each_in_batches do |p|
      found = p if p.account_id == account.account_id
      break unless found.nil?
    end
    expect(found).not_to be_nil

    # Try to retrieve it (bis repetita placent)
    invoice_payment = KillBillClient::Model::InvoicePayment.find_by_id found.payment_id
    expect(invoice_payment.account_id).to eq(account.account_id)

    # Try to retrieve it
    invoice = KillBillClient::Model::Invoice.new
    invoice.invoice_id = invoice_payment.target_invoice_id
    payments = invoice.payments
    expect(payments.size).to eq(1)
    expect(payments.first.account_id).to eq(account.account_id)

    # Add/Remove an invoice payment custom field
    expect(invoice_payment.custom_fields.size).to eq(0)
    custom_field = KillBillClient::Model::CustomField.new
    custom_field.name = SecureRandom.uuid.to_s
    custom_field.value = SecureRandom.uuid.to_s
    invoice_payment.add_custom_field(custom_field, 'KillBill Spec test')
    custom_fields = invoice_payment.custom_fields
    expect(custom_fields.size).to eq(1)
    expect(custom_fields.first.name).to eq(custom_field.name)
    expect(custom_fields.first.value).to eq(custom_field.value)
    invoice_payment.remove_custom_field(custom_fields.first.custom_field_id, 'KillBill Spec test')
    expect(invoice_payment.custom_fields.size).to eq(0)

    # Check the account balance
    account = KillBillClient::Model::Account.find_by_id account.account_id, true
    expect(account.account_balance).to eq(0)

    # Verify the timeline
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id
    expect(timeline.payments).not_to be_empty
    invoice_payment = timeline.payments.first
    expect(timeline.payments.first.transactions.size).to eq(1)
    expect(timeline.payments.first.transactions.first.transaction_type).to eq('PURCHASE')
    expect(invoice_payment.auth_amount).to eq(0)
    expect(invoice_payment.captured_amount).to eq(0)
    expect(invoice_payment.purchased_amount).to eq(invoice_payment.purchased_amount)
    expect(invoice_payment.refunded_amount).to eq(0)
    expect(invoice_payment.credited_amount).to eq(0)

    # Refund the payment (with item adjustment)
    invoice_item = KillBillClient::Model::Invoice.find_by_number(invoice_number).items.first
    item = KillBillClient::Model::InvoiceItem.new
    item.invoice_item_id = invoice_item.invoice_item_id
    item.amount = invoice_item.amount

    # Verify the refund
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id
    expect(timeline.payments).not_to be_empty
    expect(timeline.payments.size).to eq(1)
    expect(timeline.payments.first.transactions.size).to eq(1)
    expect(timeline.payments.first.transactions.first.transaction_type).to eq('PURCHASE')

    # Create a credit for invoice
    new_credit = KillBillClient::Model::Credit.new
    new_credit.amount = 10.1
    new_credit.invoice_id = invoice_id
    new_credit.start_date = "2013-09-30"
    new_credit.account_id = account.account_id

    expect { new_credit.create(true, 'KillBill Spec test') }.to raise_error(KillBillClient::API::BadRequest)

    # Verify the invoice item of the credit
    invoice = KillBillClient::Model::Invoice.find_by_id invoice_id
    expect(invoice.items).not_to be_empty
    item = invoice.items.last
    expect(item.invoice_id).to eq(invoice_id)
    expect(item.amount).to eq(123.98)
    expect(item.account_id).to eq(account.account_id)

    # Create a subscription
    sub = KillBillClient::Model::Subscription.new
    sub.account_id = account.account_id
    sub.external_key = SecureRandom.uuid.to_s
    sub.product_name = 'Sports'
    sub.product_category = 'BASE'
    sub.billing_period = 'MONTHLY'
    sub.price_list = 'DEFAULT'
    sub = sub.create 'KillBill Spec test'

    # Verify we can retrieve it
    account_bundles = account.bundles
    expect(account_bundles.size).to eq(1)
    expect(account_bundles[0].subscriptions.size).to eq(1)
    expect(account_bundles[0].subscriptions[0].subscription_id).to eq(sub.subscription_id)
    bundle = account_bundles[0]

    # Verify we can retrieve it by id
    expect(KillBillClient::Model::Bundle.find_by_id(bundle.bundle_id)).to eq(bundle)

    # Verify we can retrieve it by external key
    expect(KillBillClient::Model::Bundle.find_by_external_key(bundle.external_key, true).first).to eq(bundle)

    # Verify we can retrieve it by account id and external key
    bundles = KillBillClient::Model::Bundle.find_all_by_account_id_and_external_key(account.account_id, bundle.external_key)
    expect(bundles.size).to eq(1)
    expect(bundles[0]).to eq(bundle)

    # Try to export it
    export = KillBillClient::Model::Export.find_by_account_id(account.account_id, 'KillBill Spec test')
    expect(export).to include(account.account_id)
  end

  it 'should manipulate tag definitions' do
    expect(KillBillClient::Model::TagDefinition.all.size).to be > 0
    expect(KillBillClient::Model::TagDefinition.find_by_name('TEST').is_control_tag).to be_truthy

    tag_definition_name = SecureRandom.uuid.to_s[0..9]
    expect(KillBillClient::Model::TagDefinition.find_by_name(tag_definition_name)).to be_nil

    tag_definition = KillBillClient::Model::TagDefinition.new
    tag_definition.name = tag_definition_name
    tag_definition.description = 'Tag for unit test'
    tag_definition.applicable_object_types = [:ACCOUNT]
    expect(tag_definition.create('KillBill Spec test').id).not_to be_nil

    found_tag_definition = KillBillClient::Model::TagDefinition.find_by_name(tag_definition_name)
    expect(found_tag_definition.name).to eq(tag_definition_name)
    expect(found_tag_definition.description).to eq(tag_definition.description)
    expect(found_tag_definition.is_control_tag).to be_falsey
  end

  it 'should manipulate tenants', :integration => true  do
    api_key = SecureRandom.uuid.to_s + rand(100).to_s
    api_secret = api_key

    tenant = KillBillClient::Model::Tenant.new
    tenant.api_key = api_key
    tenant.api_secret = api_secret

    # Create and verify the tenant
    tenant = tenant.create(true, 'KillBill Spec test')
    expect(tenant.api_key).to eq(api_key)
    expect(tenant.tenant_id).not_to be_nil

    # Try to retrieve it by id
    tenant = KillBillClient::Model::Tenant.find_by_id tenant.tenant_id
    expect(tenant.api_key).to eq(api_key)

    # Try to retrieve it by api key
    tenant = KillBillClient::Model::Tenant.find_by_api_key tenant.api_key
    expect(tenant.api_key).to eq(api_key)
  end

  it 'should manipulate the catalog', :integration => true do
    plans = KillBillClient::Model::Catalog::available_base_plans
    expect(plans.size).to be > 0
    expect(plans[0].plan).not_to be_nil
  end

  #it 'should retrieve users permissions' do
  #  # Tough to verify as it depends on the Kill Bill configuration
  #  puts KillBillClient::Model::Security.find_permissions
  #  puts KillBillClient::Model::Security.find_permissions(:username => 'admin', :password => 'password')
  #end
end
