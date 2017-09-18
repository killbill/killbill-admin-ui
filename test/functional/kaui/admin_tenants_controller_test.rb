require 'test_helper'

class Kaui::AdminTenantsControllerTest < Kaui::FunctionalTestHelper

  test 'should get new' do
    post :new
    assert_response :success
  end

  test 'should get create' do
    now = Time.now.to_s
    post :create, :tenant => {:name => 'Goldorak_' + now, :api_key => '12345_' + now, :api_secret => 'ItH@st0beComplic@ted'}, :create_tenant => true
    assert_response 302
  end

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get show with allowed user' do
    tenant = Kaui::Tenant.new
    tenant.name = 'foo'
    tenant.api_key = 'api_key'
    tenant.api_secret = 'api_secret'
    tenant.kb_tenant_id = 'kb_tenant_id'
    tenant.save!

    # Add an allowed user that will verify that we can only
    au = Kaui::AllowedUser.find_by_kb_username('admin')
    au.kaui_tenants << tenant

    get :show, :id => tenant.id
    assert_response :success
  end

  test 'should get show with NO allowed user' do
    tenant = Kaui::Tenant.new
    tenant.name = 'foo'
    tenant.api_key = 'api_key'
    tenant.api_secret = 'api_secret'
    tenant.kb_tenant_id = 'kb_tenant_id'
    tenant.save!

    get :show, :id => tenant.id
    assert_response 200
  end

  test 'should upload catalog' do
    tenant = create_kaui_tenant
    post :upload_catalog, :id => tenant.id, :catalog => fixture_file_upload('catalog-v1.xml')

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Catalog was successfully uploaded', flash[:notice]
  end

  test 'should upload overdue config' do
    tenant = create_kaui_tenant
    post :upload_overdue_config, :id => tenant.id, :overdue => fixture_file_upload('overdue-v1.xml')

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Overdue config was successfully uploaded', flash[:notice]
  end

  test 'should upload invoice template' do
    tenant = create_kaui_tenant
    post :upload_invoice_template, :id => tenant.id, :invoice_template => fixture_file_upload('invoice_template-v1.html')

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Invoice template was successfully uploaded', flash[:notice]
  end

  test 'should upload invoice translation' do
    tenant = create_kaui_tenant
    post :upload_invoice_translation, :id => tenant.id, :invoice_translation => fixture_file_upload('invoice_translation_fr-v1.properties'), :translation_locale => 'fr_FR'

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Invoice translation was successfully uploaded', flash[:notice]
  end

  test 'should upload catalog translation' do
    tenant = create_kaui_tenant
    post :upload_catalog_translation, :id => tenant.id, :catalog_translation => fixture_file_upload('catalog_translation_fr-v1.properties'), :translation_locale => 'fr_FR'

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Catalog translation was successfully uploaded', flash[:notice]
  end

  test 'should upload plugin config' do
    tenant = create_kaui_tenant

    stripe_yml = YAML.load_file(File.join(self.class.fixture_path, 'stripe.yml'))[:stripe]
    stripe_yml.stringify_keys!
    stripe_yml.each { |k, v| stripe_yml[k] = v.to_s }
    post :upload_plugin_config, :id => tenant.id, :plugin_name => 'killbill-stripe', :plugin_type => 'ruby', :plugin_properties => stripe_yml

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Config for plugin was successfully uploaded', flash[:notice]
  end

  test 'should get new catalog' do
    tenant = create_kaui_tenant

    get :new_catalog, :id => tenant.id
    assert_response :success
    assert has_input_field('simple_plan_product_name')
  end

  test 'should get new plan currency' do
    tenant = create_kaui_tenant
    plain_id = 'sailboat12345678910'

    get :new_plan_currency, :id => tenant.id, :plan_id => plain_id
    assert_response :success
    assert_equal get_value_from_input_field('simple_plan_plan_id'), plain_id
  end

  test 'should create and delete a catalog' do
    tenant = create_kaui_tenant

    parameters = {
      :id => tenant.id,
      :simple_plan => {
          :product_category => 'STANDALONE',
          :product_name => 'Boat Rental',
          :plan_id => 'boat12345678910',
          :amount => 10,
          :currency => 'USD',
          :billing_period => 'MONTHLY',
          :trial_length => 0,
          :trial_time_unit => 'UNLIMITED'
      }
    }
    post :create_simple_plan, parameters
    assert_response :redirect
    expected_response_path = "/admin_tenants/#{tenant.id}"
    assert_equal 'Catalog plan was successfully added', flash[:notice]
    assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"


    delete :delete_catalog, :id => tenant.id
    assert_response :redirect

    if !flash[:error].nil? && flash[:error].to_s.eql?('Failed to delete catalog: only available in KB 0.19+ versions')
      assert response_path.include?('/admin_tenants'), "#{response_path} is expected to contain /admin_tenants"
    else
      assert_equal 'Catalog was successfully deleted', flash[:notice]
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
    end

  end

  test 'should remove allowed user' do
    tenant = create_kaui_tenant

    au = Kaui::AllowedUser.new
    au.kb_username = 'Voltron'
    au.description = 'Defender of the Universe'
    au.save!

    parameters = {
      :id => tenant.id,
      :allowed_user => { :id => au.id }
    }

    delete :remove_allowed_user, parameters
    assert_response :success
  end

  test 'should modify overdue config' do
    tenant = create_kaui_tenant

    parameters = {
      :id => tenant.id,
      :kill_bill_client_model_overdue => {
        :states => [{
          :name =>	'Overdue_test',
          :external_message => 'Overdue_Test_Ya',
          :block_changes =>	true,
          :subscription_cancellation_policy => 'NONE',
          :condition => {
            :time_since_earliest_unpaid_invoice_equals_or_exceeds => 1,
            :control_tag_inclusion =>	'NONE',
            :control_tag_exclusion =>	'NONE',
          }
        }]
      }
    }

    post :modify_overdue_config, parameters
    assert_response :redirect
    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Overdue config was successfully added', flash[:notice].to_s.strip
  end

  test 'should display catalog xml' do
    catalog_xml = File.open(File.join(self.class.fixture_path, 'catalog-v1.xml'),'r'){|io| io.read}
    post :display_catalog_xml, :xml => catalog_xml

    assert_equal @response.body, catalog_xml
  end

  test 'should display overdue xml' do
    overdue_xml = File.open(File.join(self.class.fixture_path, 'overdue-v1.xml'),'r'){|io| io.read}
    post :display_overdue_xml, :xml => overdue_xml

    assert_equal @response.body, overdue_xml
  end

  private

  def create_kaui_tenant
    post :create,
         :tenant => {:name => SecureRandom.uuid.to_s, :api_key => SecureRandom.uuid.to_s, :api_secret => SecureRandom.uuid.to_s},
         :create_tenant => true

    tenant = Kaui::Tenant.last
    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Tenant was successfully configured', flash[:notice]
    tenant
  end
end
