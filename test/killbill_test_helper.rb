# frozen_string_literal: true

module Kaui
  module KillbillTestHelper
    USERNAME = 'admin'
    PASSWORD = 'password'

    #
    # Rails helpers
    #

    def check_no_flash_error
      unless flash.now.nil?
        assert_nil flash.now[:alert], "Found flash alert: #{flash.now[:alert]}"
        assert_nil flash.now[:error], "Found flash error: #{flash.now[:error]}"
      end
      assert_nil flash[:alert]
      assert_nil flash[:error]
    end

    #
    # Kill Bill specific helpers
    #

    def setup_test_data(nb_configured_tenants, setup_tenant_key_secret, tenant_data = {})
      @tenant_data = tenant_data
      @tenant            = setup_and_create_test_tenant(nb_configured_tenants)
      @account           = create_account(@tenant)
      @account2          = create_account(@tenant)
      @bundle            = create_bundle(@account, @tenant)
      @invoice_item      = create_charge(@account, @tenant)
      @paid_invoice_item = create_charge(@account, @tenant, true)
      @bundle_invoice    = @account.invoices({ params: { includeInvoiceComponents: true } }.merge(build_options(@tenant))).first
      @payment_method    = create_payment_method(true, @account, @tenant)
      @payment           = create_payment(@paid_invoice_item, @account, @tenant)

      invoice_id_for_cba = create_charge(@account, @tenant).invoice_id
      @cba               = create_cba(invoice_id_for_cba, @account, @tenant, true)
      commit_invoice(invoice_id_for_cba, @tenant)

      if setup_tenant_key_secret
        KillBillClient.api_key = @tenant.api_key
        KillBillClient.api_secret = @tenant.api_secret
      else
        KillBillClient.api_key = nil
        KillBillClient.api_secret = nil
      end
      KillBillClient.username = USERNAME
      KillBillClient.password = PASSWORD
      @tenant
    end

    def setup_and_create_test_tenant(nb_configured_tenants)
      # If we need to configure 0 tenant, we still create one with Kill Bill but add nothing in the kaui_tenants and kaui_allowed_users tables
      return create_tenant if nb_configured_tenants.zero?

      # Setup AllowedUser
      au = Kaui::AllowedUser.find_or_create_by(kb_username: 'admin')

      # Create the tenant with Kill Bill
      all_tenants = []
      test_tenant = nil
      (1..nb_configured_tenants).each do |_i|
        cur_tenant = create_tenant
        test_tenant = cur_tenant if test_tenant.nil?

        t = Kaui::Tenant.new
        t.kb_tenant_id = cur_tenant.tenant_id
        t.name = SecureRandom.uuid.to_s
        t.api_key = cur_tenant.api_key
        t.api_secret = cur_tenant.api_secret
        t.save
        all_tenants << t
      end

      # setup kaui_tenants
      all_tenants.each { |e| au.kaui_tenants << e } unless all_tenants.empty?
      test_tenant
    end

    # Return a new test account
    def create_account(tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil, parent_account_id = nil)
      tenant       = create_tenant if tenant.nil?
      external_key = SecureRandom.uuid.to_s

      account                          = KillBillClient::Model::Account.new
      account.name                     = 'Kaui'
      account.external_key             = external_key
      account.email                    = 'kill@bill.com'
      account.currency                 = 'USD'
      account.time_zone                = 'UTC'
      account.address1                 = '5, ruby road'
      account.address2                 = 'Apt 4'
      account.postal_code              = 10_293
      account.company                  = 'KillBill, Inc.'
      account.city                     = 'SnakeCase'
      account.state                    = 'Awesome'
      account.country                  = 'LalaLand'
      account.locale                   = 'fr_FR'
      account.parent_account_id        = parent_account_id
      account.is_payment_delegated_to_parent = !parent_account_id.nil?

      account.create(user, reason, comment, build_options(tenant, username, password))
    end

    # Return the killbill server clock
    def get_clock(tenant = nil)
      tenant = create_tenant(user, reason, comment) if tenant.nil?
      Kaui::Admin.get_clock(nil, build_options(tenant, USERNAME, PASSWORD))
    end

    # reset killbill server clock
    def reset_clock
      Kaui::Admin.set_clock(nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    end

    # Return the created bundle
    def create_bundle(account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant(user, reason, comment) if tenant.nil?
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      entitlement = KillBillClient::Model::Subscription.new(account_id: account.account_id,
                                                            external_key: SecureRandom.uuid,
                                                            product_name: 'Sports', # Sports, so we can add addons
                                                            product_category: 'BASE',
                                                            billing_period: 'MONTHLY',
                                                            price_list: 'DEFAULT')
      entitlement = entitlement.create(user, reason, comment, nil, false, build_options(tenant, username, password))

      KillBillClient::Model::Bundle.find_by_id(entitlement.bundle_id, build_options(tenant, username, password))
    end

    # Return a new test payment method
    # rubocop:disable Style/OptionalBooleanParameter
    def create_payment_method(set_default = false, account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      payment_method = Kaui::PaymentMethod.new(account_id: account.account_id, plugin_name: '__EXTERNAL_PAYMENT__', is_default: set_default)
      payment_method.create(true, user, reason, comment, build_options(tenant, username, password))
    end
    # rubocop:enable Style/OptionalBooleanParameter

    # Return the created external charge
    # rubocop:disable Style/OptionalBooleanParameter
    def create_charge(account = nil, tenant = nil, auto_commit = false, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant(user, reason, comment) if tenant.nil?
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      invoice_item            = KillBillClient::Model::InvoiceItem.new
      invoice_item.account_id = account.account_id
      invoice_item.currency   = account.currency
      invoice_item.amount     = 123.98

      invoice_item.create(auto_commit, user, reason, comment, build_options(tenant, username, password))
    rescue StandardError
      nil
    end
    # rubocop:enable Style/OptionalBooleanParameter

    # Return the created credit
    # rubocop:disable Style/OptionalBooleanParameter
    def create_cba(invoice_id = nil, account = nil, tenant = nil, _auto_commit = false, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant(user, reason, comment) if tenant.nil?
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      credit = KillBillClient::Model::Credit.new(invoice_id:, account_id: account.account_id, amount: 23.22)
      credit = credit.create(true, user, reason, comment, build_options(tenant, username, password)).first

      invoice = KillBillClient::Model::Invoice.find_by_id(credit.invoice_id, 'NONE', build_options(tenant, username, password))
      invoice.items.find { |ii| ii.amount == -credit.amount }
    end
    # rubocop:enable Style/OptionalBooleanParameter

    def commit_invoice(invoice_id, tenant, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      invoice = KillBillClient::Model::Invoice.find_by_id(invoice_id, 'NONE', build_options(tenant, username, password))
      invoice.commit(user, reason, comment, build_options(tenant, username, password))
    end

    def create_payment(invoice_item = nil, account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant       = create_tenant(user, reason, comment) if tenant.nil?
      account      = create_account(tenant, username, password, user, reason, comment) if account.nil?
      invoice_item = create_charge(account, tenant, true, username, password, user, reason, comment) if invoice_item.nil?

      assert_not_nil invoice_item

      payment = Kaui::InvoicePayment.new({ account_id: account.account_id, target_invoice_id: invoice_item.invoice_id, purchased_amount: invoice_item.amount })
      payment.create(true, user, reason, comment, build_options(tenant, username, password))
    end

    # Return a new test tenant
    def create_tenant(user = 'Kaui test', reason = nil, comment = nil)
      api_key    = SecureRandom.uuid.to_s
      api_secret = 'S4cr3333333t!!!!!!lolz'

      tenant            = KillBillClient::Model::Tenant.new
      tenant.api_key    = api_key
      tenant.api_secret = api_secret

      tenant = tenant.create(true, user, reason, comment, build_options)

      # Re-hydrate the secret, which is not returned
      tenant.api_secret = api_secret

      # Upload the default SpyCarAdvanced.xml catalog
      catalog_xml = File.read((@tenant_data && @tenant_data[:catalog_file]) || 'test/fixtures/SpyCarAdvanced.xml')
      Kaui::AdminTenant.upload_catalog(catalog_xml, user, reason, comment, build_options(tenant))

      tenant
    end

    def build_options(tenant = nil, username = USERNAME, password = PASSWORD)
      {
        api_key: tenant&.api_key,
        api_secret: tenant&.api_secret,
        username:,
        password:
      }
    end

    def options
      build_options(@tenant)
    end
  end
end
