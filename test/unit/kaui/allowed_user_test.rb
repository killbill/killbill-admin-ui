# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AllowedUserTest < ActiveSupport::TestCase
    test 'basic' do
      au = AllowedUser.new(kb_username: 'Jean', description: 'Cool guy')
      au.save

      result = AllowedUser.find_by_kb_username('Jean')
      assert_not_nil result
      assert_equal au, result
    end

    test 'with tenants' do
      au = AllowedUser.new(kb_username: 'Girish', description: 'Unknown')
      au.save

      t1 = Tenant.new(name: 't1', api_key: 'key1', api_secret: 'secret1', kb_tenant_id: 'e87a41c8-bc04-4de7-914e-514028b39af9')
      t1.save
      au.kaui_tenants << t1

      t2 = Tenant.new(name: 't2', api_key: 'key2', api_secret: 'secret2', kb_tenant_id: 'f9b9a032-907a-4caa-b90f-c4c7601c4d54')
      t2.save
      au.kaui_tenants << t2

      result = AllowedUser.find_by_kb_username('Girish')
      assert_not_nil result
      assert_equal 2, au.kaui_tenants.size
    end
  end
end
