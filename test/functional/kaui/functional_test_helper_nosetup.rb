class Kaui::FunctionalTestHelperNoSetup < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include Kaui::KillbillTestHelper

  protected

  self.fixture_path = Kaui::Engine.root.join('test', "fixtures")

  #
  # Rails helpers
  #

  def setup_functional_test(nb_configured_tenants = 1, setup_tenant_key_secret=true)
    # Create useful data to exercise the code
    created_tenant = setup_test_data(nb_configured_tenants, setup_tenant_key_secret)

    @routes                        = Kaui::Engine.routes
    @request.env['devise.mapping'] = Devise.mappings[:user]

    # Login
    login_as_admin
    # Set the tenant parameter in the session manually since  login_as_admin will erase the previous value
    session[:kb_tenant_id] = created_tenant.tenant_id
  end

  def teardown_functional_test
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
      post :create, {:user => {:kb_username => USERNAME, :password => PASSWORD}}
    end
  end

  # Cheat to access a different controller
  def wrap_with_controller(new_controller = Kaui::SessionsController)
    old_controller = @controller
    @controller    = new_controller.new
    yield
    @controller = old_controller
  end

  # To ease the upgrade... inspired by https://stackoverflow.com/a/43787973
  # See https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/test_case.rb
  def get(action, **args)
    res = process(action, method: "GET", params: args)
    cookies.update res.cookies
    res
  end
  def post(action, **args)
    process(action, method: "POST", params: args)
  end
  def put(action, **args)
    process(action, method: "PUT", params: args)
  end
  def delete(action, **args)
    process(action, method: "DELETE", params: args)
  end
  def head(action, **args)
    process(action, method: "HEAD", params: args)
  end
  def patch(action, **args)
    process(action, method: "PATCH", params: args)
  end
end
