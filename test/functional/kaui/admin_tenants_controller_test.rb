require 'test_helper'

module Kaui
  class AdminTenantsControllerTest < Kaui::FunctionalTestHelper
    test 'should get new' do
      post :new
      assert_response :success
    end

    test 'should get create' do
      now = Time.now.to_s
      post :create, {:tenant => {:name => 'Goldorak_' + now, :api_key => '12345_' + now, :api_secret => 'ItH@st0beComplic@ted'}, :create_tenant => true}
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
      assert_response 302
    end
  end
end
