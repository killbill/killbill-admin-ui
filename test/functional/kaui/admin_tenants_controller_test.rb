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
    post :upload_plugin_config, :id => tenant.id, :plugin_name => 'killbill-stripe', :plugin_config => fixture_file_upload('stripe.yml')

    assert_redirected_to admin_tenant_path(tenant.id)
    assert_equal 'Config for plugin was successfully uploaded', flash[:notice]
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
