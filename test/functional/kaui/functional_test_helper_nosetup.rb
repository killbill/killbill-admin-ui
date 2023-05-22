# frozen_string_literal: true

module Kaui
  class FunctionalTestHelperNoSetup < ActionController::TestCase
    include Devise::Test::ControllerHelpers
    include Kaui::KillbillTestHelper

    protected

    self.fixture_path = Kaui::Engine.root.join('test', 'fixtures')

    #
    # Rails helpers
    #

    def setup_functional_test(nb_configured_tenants, setup_tenant_key_secret, tenant_data = {})
      # Create useful data to exercise the code
      created_tenant = setup_test_data(nb_configured_tenants, setup_tenant_key_secret, tenant_data)
      @routes                        = Kaui::Engine.routes
      @request.env['devise.mapping'] = Devise.mappings[:user]

      # Login
      login_as_admin
      # Set the tenant parameter in the session manually since  login_as_admin will erase the previous value
      session[:kb_tenant_id] = created_tenant.tenant_id

      # get the killbill server clock
      @kb_clock = get_clock(@tenant)
    end

    def teardown_functional_test
      reset_clock
    end

    def verify_pagination_results!(min = 0)
      assert_response 200

      body = MultiJson.decode(@response.body)
      # We could probably do better checks here since each test runs in its own tenant
      assert body['recordsTotal'] >= min
      assert body['recordsFiltered'] >= min
      assert body['data'].instance_of?(Array)
      assert body['error'].nil?
    end

    def login_as_admin
      wrap_with_controller do
        get :new
        post :create, params: { user: { kb_username: USERNAME, password: PASSWORD } }
      end
    end

    def logout
      wrap_with_controller do
        post :destroy
      end
    end

    # Cheat to access a different controller
    def wrap_with_controller(new_controller = Kaui::SessionsController)
      old_controller = @controller
      @controller    = new_controller.new
      yield
      @controller = old_controller
    end

    # response related methods
    def response_path
      return nil if @response.nil? || !@response.has_header?('Location')

      URI(@response.get_header('Location')).path
    end

    def extract_value_from_input_field(input_id_name)
      return nil if input_id_name.nil? || @response.nil? || @response.body.nil?

      # pattern where id/name is after the value
      pattern1 = Regexp.new("<input.*value=\"(?<value>.+?)\".*(id=.#{input_id_name}|name=.#{input_id_name})..*>")

      # pattern where id/name is before the value
      pattern2 = Regexp.new("<input.*(id=.#{input_id_name}|name=.#{input_id_name})..*value=\"(?<value>.+?)\".*>")

      input = pattern1.match(@response.body)
      input = pattern2.match(@response.body) if input.nil?

      input.nil? ? nil : input[:value]
    end

    def input_field?(input_id_name)
      return nil if input_id_name.nil? || @response.nil? || @response.body.nil?

      pattern = Regexp.new("<input.*(id=.#{input_id_name}|name=.#{input_id_name})..*>")
      input = pattern.match(@response.body)

      !input.nil?
    end
  end
end
