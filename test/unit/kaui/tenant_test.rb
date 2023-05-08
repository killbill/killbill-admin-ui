# frozen_string_literal: true

require 'test_helper'
require 'symmetric-encryption'

module Kaui
  class TenantTest < ActiveSupport::TestCase
    test 'basic' do
      SymmetricEncryption.load!('config/symmetric-encryption.yml', 'test')
      t = Tenant.new(name: 'archibald', api_key: 'kk', api_secret: 's$per$ecret!', kb_tenant_id: 'e87a41c8-bc04-4de7-914e-514028b39af9')
      t.save

      result = Tenant.find_by_name('archibald')
      assert_not_nil result
      assert_equal t, result
      assert_equal t.api_secret, result.api_secret
    end
  end
end
