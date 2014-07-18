module Kaui
  module KillbillTestHelper

    USERNAME = 'admin'
    PASSWORD = 'password'

    #
    # Rails helpers
    #

    def check_no_flash_error
      unless flash.now.nil?
        assert_nil flash.now[:alert], 'Found flash alert: ' + flash.now[:alert].to_s
        assert_nil flash.now[:error], 'Found flash error: ' + flash.now[:error].to_s
      end
      assert_nil flash[:alert]
      assert_nil flash[:error]
    end

    #
    # Kill Bill specific helpers
    #

    def setup_test_data
      @tenant            = create_tenant
      @account           = create_account(@tenant)
      @account2          = create_account(@tenant)
      @bundle            = create_bundle(@account, @tenant)
      @payment_method    = create_payment_method(true, @account, @tenant)
      @invoice_item      = create_charge(@account, @tenant)
      @paid_invoice_item = create_charge(@account, @tenant)
      @payment           = create_payment(@paid_invoice_item, @account, @tenant)
    end

    # Return a new test account
    def create_account(tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
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
      account.postal_code              = 10293
      account.company                  = 'KillBill, Inc.'
      account.city                     = 'SnakeCase'
      account.state                    = 'Awesome'
      account.country                  = 'LalaLand'
      account.locale                   = 'fr_FR'
      account.is_notified_for_invoices = false

      account.create(user, reason, comment, build_options(tenant, username, password))
    end

    # Return the created bundle
    def create_bundle(account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant(user, reason, comment) if tenant.nil?
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      entitlement = KillBillClient::Model::Subscription.new(:account_id       => account.account_id,
                                                            :external_key     => SecureRandom.uuid,
                                                            :product_name     => 'Sports', # Sports, so we can add addons
                                                            :product_category => 'BASE',
                                                            :billing_period   => 'MONTHLY',
                                                            :price_list       => 'DEFAULT')
      entitlement = entitlement.create(user, reason, comment, build_options(tenant, username, password))

      KillBillClient::Model::Bundle.find_by_id(entitlement.bundle_id, build_options(tenant, username, password))
    end

    # Return a new test payment method
    def create_payment_method(set_default = false, account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      payment_method = Kaui::PaymentMethod.new(:account_id => account.account_id, :plugin_name => '__EXTERNAL_PAYMENT__', :is_default => set_default)
      payment_method.create(user, reason, comment, build_options(tenant, username, password))
    end

    # Return the created external charge
    def create_charge(account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant(user, reason, comment) if tenant.nil?
      account = create_account(tenant, username, password, user, reason, comment) if account.nil?

      invoice_item            = KillBillClient::Model::InvoiceItem.new
      invoice_item.account_id = account.account_id
      invoice_item.currency   = account.currency
      invoice_item.amount     = 123.98

      invoice_item.create(user, reason, comment, build_options(tenant, username, password))
    end

    def create_payment(invoice_item = nil, account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant       = create_tenant(user, reason, comment) if tenant.nil?
      account      = create_account(tenant, username, password, user, reason, comment) if account.nil?
      invoice_item = create_charge(account, tenant, username, password, user, reason, comment) if invoice_item.nil?

      payment = Kaui::InvoicePayment.new({:account_id => account.account_id, :target_invoice_id => invoice_item.invoice_id, :purchased_amount => invoice_item.amount})
      payment.create(true, user, reason, comment, build_options(tenant, username, password))
    end

    # Return a new test tenant
    def create_tenant(user = 'Kaui test', reason = nil, comment = nil)
      api_key    = SecureRandom.uuid.to_s
      api_secret = 'S4cr3333333t!!!!!!lolz'

      tenant            = KillBillClient::Model::Tenant.new
      tenant.api_key    = api_key
      tenant.api_secret = api_secret

      tenant.create(user, reason, comment, build_options)
    end

    def build_options(tenant = nil, username = USERNAME, password = PASSWORD)
      {
          :api_key    => tenant.nil? ? nil : tenant.api_key,
          :api_secret => tenant.nil? ? nil : tenant.api_secret,
          :username   => username,
          :password   => password
      }
    end

    def options
      build_options(@tenant)
    end
  end
end
