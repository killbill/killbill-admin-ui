require 'test_helper'

module Kaui
  class AdminTenantsControllerTest < Kaui::FunctionalTestHelper

    test "should get new" do
      post :new
      assert_response :success
    end

    test "should get create" do
      now = Time.now.to_s
      post :create, :tenant => { :name => 'Goldorak_' + now, :api_key => '12345_' + now, :api_secret => 'ItH@st0beComplic@ted'}
      assert_response 302
    end


    test "should get show" do
      tenant = Kaui::Tenant.new
      tenant.name = 'foo'
      tenant.api_key = 'api_key'
      tenant.api_secret = 'api_secret'
      tenant.kb_tenant_id = 'kb_tenant_id'
      tenant.save!
      get :show, :id => tenant.id
      assert_response :success
    end


    test "should get index" do
      get :index
      assert_response :success
    end
  end
end
