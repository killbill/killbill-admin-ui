module Kaui
  module FunctionalTestHelper

    USERNAME = 'admin'
    PASSWORD = 'password'

    #
    # Rails helpers
    #

    def setup_functional_test
      @routes                        = Engine.routes
      @request.env['devise.mapping'] = Devise.mappings[:user]

      # Login
      get :index
      assert_redirected_to :new_user_session
      login_as_admin
    end

    def verify_pagination_results!(min = 0)
      assert_response 200

      body = MultiJson.decode(@response.body)
      assert body['iTotalRecords'] >= min
      assert body['iTotalDisplayRecords'] >= min
      assert body['aaData'].instance_of?(Array)
    end

    def login_as_admin
      wrap_with_controller do
        post :create, {:user => {:kb_username => USERNAME, :password => PASSWORD}}
      end
    end

    # Cheat to access a different controller
    def wrap_with_controller(new_controller = SessionsController)
      old_controller = @controller
      @controller    = new_controller.new
      yield
      @controller = old_controller
    end

    #
    # Kill Bill helpers
    #

    # Return a new test account
    def create_account(tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant       = create_tenant if tenant.nil?
      external_key = Time.now.to_i.to_s

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
      account.locale                   = 'FR_fr'
      account.is_notified_for_invoices = false

      account.create(user, reason, comment, build_options(tenant, username, password))
    end

    # Return the created external charge
    def create_charge(account = nil, tenant = nil, username = USERNAME, password = PASSWORD, user = 'Kaui test', reason = nil, comment = nil)
      tenant  = create_tenant if tenant.nil?
      account = create_account(tenant) if account.nil?

      invoice_item            = KillBillClient::Model::InvoiceItem.new
      invoice_item.account_id = account.account_id
      invoice_item.currency   = account.currency
      invoice_item.amount     = 123.98

      invoice_item.create(user, reason, comment, build_options(tenant, username, password))
    end

    # Return a new test tenant
    def create_tenant(user = 'Kaui test', reason = nil, comment = nil)
      api_key    = Time.now.to_i.to_s
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
  end
end
