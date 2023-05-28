# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AdminTenantsControllerTest < Kaui::FunctionalTestHelper
    FIXTURES_PATH = '../../../../../test/fixtures'

    test 'should get new' do
      post :new
      assert_response :success
    end

    test 'should get create' do
      now = Time.now.to_s
      post :create, params: { tenant: { name: "Goldorak_#{now}", api_key: "12345_#{now}", api_secret: 'ItH@st0beComplic@ted' }, create_tenant: true }
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

      get :show, params: { id: tenant.id }
      assert_response :success
    end

    test 'should get show with NO allowed user' do
      tenant = Kaui::Tenant.new
      tenant.name = 'foo'
      tenant.api_key = 'api_key'
      tenant.api_secret = 'api_secret'
      tenant.kb_tenant_id = 'kb_tenant_id'
      tenant.save!

      get :show, params: { id: tenant.id }
      assert_response 200
    end

    test 'should upload catalog' do
      tenant = create_kaui_tenant
      post :upload_catalog, params: { id: tenant.id, catalog: fixture_file_upload("#{FIXTURES_PATH}/catalog-v1.xml") }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.catalog_uploaded_successfully'), flash[:notice]
    end

    test 'should upload overdue config' do
      tenant = create_kaui_tenant
      post :upload_overdue_config, params: { id: tenant.id, overdue: fixture_file_upload("#{FIXTURES_PATH}/overdue-v1.xml") }

      assert_redirected_to admin_tenant_path(tenant.id, active_tab: 'OverdueShow')
      assert_equal I18n.translate('flashes.notices.overdue_uploaded_successfully'), flash[:notice]
    end

    test 'should raise missing param when upload an empty file' do
      tenant = create_kaui_tenant
      post :upload_catalog, params: { id: tenant.id }
      assert_equal 'Required parameter missing: catalog', flash[:error]

      post :upload_overdue_config, params: { id: tenant.id }
      assert_equal 'Required parameter missing: overdue', flash[:error]

      post :upload_invoice_template, params: { id: tenant.id }
      assert_equal 'Required parameter missing: invoice_template', flash[:error]

      post :upload_invoice_translation, params: { id: tenant.id }
      assert_equal 'Required parameter missing: invoice_translation', flash[:error]

      post :upload_catalog_translation, params: { id: tenant.id }
      assert_equal 'Required parameter missing: catalog_translation', flash[:error]
    end

    test 'should upload invoice template' do
      tenant = create_kaui_tenant
      post :upload_invoice_template, params: { id: tenant.id, invoice_template: fixture_file_upload("#{FIXTURES_PATH}/invoice_template-v1.html") }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.invoice_template_uploaded_successfully'), flash[:notice]
    end

    test 'should upload invoice translation' do
      tenant = create_kaui_tenant
      post :upload_invoice_translation, params: { id: tenant.id, invoice_translation: fixture_file_upload("#{FIXTURES_PATH}/invoice_translation_fr-v1.properties"), translation_locale: 'fr_FR' }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.invoice_translation_uploaded_successfully'), flash[:notice]
    end

    test 'should upload catalog translation' do
      tenant = create_kaui_tenant
      post :upload_catalog_translation, params: { id: tenant.id, catalog_translation: fixture_file_upload("#{FIXTURES_PATH}/catalog_translation_fr-v1.properties"), translation_locale: 'fr_FR' }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.catalog_translation_uploaded_successfully'), flash[:notice]
    end

    test 'should upload plugin config' do
      tenant = create_kaui_tenant

      stripe_yml = YAML.load_file(File.join(self.class.fixture_path, 'stripe.yml'))[:stripe]
      stripe_yml.stringify_keys!
      stripe_yml.each { |k, v| stripe_yml[k] = v.to_s }
      post :upload_plugin_config, params: { id: tenant.id, plugin_name: 'killbill-stripe', plugin_key: 'stripe', plugin_type: 'ruby', plugin_properties: stripe_yml }

      assert_redirected_to admin_tenant_path(tenant.id, active_tab: 'PluginConfig')
      assert_equal 'Config for plugin was successfully uploaded', flash[:notice]
    end

    test 'should get new catalog' do
      tenant = create_kaui_tenant

      get :new_catalog, params: { id: tenant.id }
      assert_response :success
      assert input_field?('simple_plan_product_name')
    end

    test 'should get new plan currency' do
      tenant = create_kaui_tenant

      # retrieve plan id from catalog xml
      catalog_xml = File.read(File.join(self.class.fixture_path, 'catalog-v1.xml'))
      doc = Nokogiri::XML(catalog_xml)
      plan_id = doc.css('plan').first['name']

      # upload catalog first
      post :upload_catalog, params: { id: tenant.id, catalog: fixture_file_upload("#{FIXTURES_PATH}/catalog-v1.xml") }
      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.catalog_uploaded_successfully'), flash[:notice]

      get :new_plan_currency, params: { id: tenant.id, plan_id: }
      assert_response :success
      assert_equal extract_value_from_input_field('simple_plan_plan_id'), plan_id

      # test for invalid plan id
      get :new_plan_currency, params: { id: tenant.id, plan_id: 'DUMMY' }
      assert_response :redirect
      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal flash[:error], 'Plan id DUMMY was not found.'
    end

    test 'should create and delete a catalog' do
      tenant = create_kaui_tenant

      parameters = {
        id: tenant.id,
        simple_plan: {
          product_category: 'STANDALONE',
          product_name: 'Boat_Rental',
          plan_id: 'boat12345678910',
          amount: 10,
          currency: 'USD',
          billing_period: 'MONTHLY',
          trial_length: 0,
          trial_time_unit: 'UNLIMITED'
        }
      }
      post :create_simple_plan, params: parameters
      assert_response :redirect
      expected_response_path = "/admin_tenants/#{tenant.id}"
      assert_equal 'Catalog plan was successfully added', flash[:notice]
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

      delete :delete_catalog, params: { id: tenant.id }
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
        id: tenant.id,
        allowed_user: { id: au.id }
      }

      delete :remove_allowed_user, params: parameters
      assert_response :success
    end

    test 'should modify overdue config' do
      tenant = create_kaui_tenant

      parameters = {
        id: tenant.id,
        kill_bill_client_model_overdue: {
          states: { '0' => {
            name: 'Overdue_test',
            external_message: 'Overdue_Test_Ya',
            is_block_changes: true,
            subscription_cancellation_policy: 'NONE',
            condition: {
              time_since_earliest_unpaid_invoice_equals_or_exceeds: 1,
              control_tag_inclusion: 'NONE',
              control_tag_exclusion: 'NONE',
              number_of_unpaid_invoices_equals_or_exceeds: 0,
              total_unpaid_invoice_balance_equals_or_exceeds: 0
            }
          } }
        }
      }

      post :modify_overdue_config, params: parameters
      assert_response :redirect
      assert_redirected_to admin_tenant_path(tenant.id, active_tab: 'OverdueShow')
      assert_equal I18n.translate('flashes.notices.overdue_added_successfully'), flash[:notice].to_s.strip
    end

    test 'should display catalog xml' do
      effective_date = '2013-02-08T00:00:00+00:00'
      tenant = create_kaui_tenant
      post :upload_catalog, params: { id: tenant.id, catalog: fixture_file_upload("#{FIXTURES_PATH}/catalog-v1.xml") }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.catalog_uploaded_successfully'), flash[:notice]

      post :display_catalog_xml, params: { effective_date:, id: tenant.id }

      doc = nil
      assert_nothing_raised { doc = Nokogiri::XML(@response.body, &:strict) }

      catalog = doc.xpath('//catalog')
      expected_effective_date = Date.parse(catalog[0].search('effectiveDate').text)

      assert_equal Date.parse(effective_date), expected_effective_date
    end

    test 'should display overdue xml' do
      overdue_xml = File.read(File.join(self.class.fixture_path, 'overdue-v1.xml'))
      post :display_overdue_xml, params: { xml: overdue_xml }

      assert_equal @response.body, overdue_xml
    end

    test 'should get a catalog by effective date' do
      effective_date = '2013-02-08T00:00:00+00:00'
      tenant = create_kaui_tenant
      post :upload_catalog, params: { id: tenant.id, catalog: fixture_file_upload("#{FIXTURES_PATH}/catalog-v1.xml") }

      get :catalog_by_effective_date, params: { id: tenant.id, effective_date: }
      assert_response :success

      result = nil
      assert_nothing_raised { result = JSON.parse(@response.body) }
      assert_not_nil(result)
      assert_equal 1, result['catalog'].size
      assert_equal Date.parse(effective_date), Date.parse(result['catalog'][0]['version_date'])
    end

    test 'should add an allowed user' do
      tenant = Kaui::Tenant.new
      tenant.name = 'foo'
      tenant.api_key = 'api_key'
      tenant.api_secret = 'api_secret'
      tenant.kb_tenant_id = 'kb_tenant_id'
      tenant.save!

      # create a new user
      au = Kaui::AllowedUser.new(kb_username: 'Hulk', description: 'He is green')
      au.save

      # add user to allowed list
      parameters = {
        allowed_user: { kb_username: au.kb_username },
        tenant_id: tenant.id
      }
      put :add_allowed_user, params: parameters
      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal 'Allowed user was successfully added', flash[:notice]

      # try to add non existent user
      parameters = {
        allowed_user: { kb_username: 'Steve Rogers' },
        tenant_id: tenant.id
      }
      put :add_allowed_user, params: parameters
      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal "User #{parameters[:allowed_user][:kb_username]} does not exist!", flash[:error]
    end

    test 'should switch tenant' do
      other_tenant = setup_and_create_test_tenant(1)
      other_tenant_kaui = Kaui::Tenant.find_by_kb_tenant_id(other_tenant.tenant_id)

      get :switch_tenant, params: { kb_tenant_id: other_tenant.tenant_id }
      assert_redirected_to admin_tenant_path(other_tenant_kaui.id)
      assert_equal flash[:notice], "Tenant was switched to #{other_tenant_kaui.name}"

      # switch back
      tenant_kaui = Kaui::Tenant.find_by_kb_tenant_id(@tenant.tenant_id)
      get :switch_tenant, params: { kb_tenant_id: @tenant.tenant_id }
      assert_redirected_to admin_tenant_path(tenant_kaui.id)
      assert_equal flash[:notice], "Tenant was switched to #{tenant_kaui.name}"
    end

    test 'should download a catalog' do
      effective_date = '2013-02-08T00:00:00+00:00'
      tenant = create_kaui_tenant
      post :upload_catalog, params: { id: tenant.id, catalog: fixture_file_upload("#{FIXTURES_PATH}/catalog-v1.xml") }

      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal I18n.translate('flashes.notices.catalog_uploaded_successfully'), flash[:notice]

      get :download_catalog_xml, params: { effective_date:, id: tenant.id }
      assert_response :success
      assert_equal 'application/xml', @response.header['Content-Type']
      assert_equal ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: "catalog_#{effective_date}.xml"), @response.header['Content-Disposition']

      doc = nil
      assert_nothing_raised { doc = Nokogiri::XML(@response.body, &:strict) }

      catalog = doc.xpath('//catalog')
      expected_effective_date = Date.parse(catalog[0].search('effectiveDate').text)

      assert_equal Date.parse(effective_date), expected_effective_date
    end

    private

    def create_kaui_tenant
      post :create,
           params: {
             tenant: { name: SecureRandom.uuid.to_s, api_key: SecureRandom.uuid.to_s, api_secret: SecureRandom.uuid.to_s },
             create_tenant: true
           }

      tenant = Kaui::Tenant.last
      assert_redirected_to admin_tenant_path(tenant.id)
      assert_equal 'Tenant was successfully configured', flash[:notice]
      tenant
    end

    def installed_plugins
      installed_plugins = []
      nodes_info = KillBillClient::Model::NodesInfo.nodes_info(build_options(@tenant, USERNAME, PASSWORD)) || []
      plugins_info = nodes_info.first.plugins_info || []
      plugins_info.each do |plugin|
        next if plugin.plugin_key.nil? || plugin.version.nil?
        next if installed_plugins.any? { |p| p[:plugin_name].eql?(plugin.plugin_name) }

        installed_plugins << {
          plugin_key: plugin.plugin_key,
          plugin_name: plugin.plugin_name
        }
      end

      installed_plugins
    end
  end
end
