class Kaui::FunctionalTestHelperNoSetup < ActionController::TestCase

  include Devise::TestHelpers
  include Kaui::KillbillTestHelper

  protected

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
    assert body['iTotalRecords'] >= min
    assert body['iTotalDisplayRecords'] >= min
    assert body['aaData'].instance_of?(Array)
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
end
