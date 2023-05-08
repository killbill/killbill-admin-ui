# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountChildrenControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index, params: { account_id: @account.account_id }
      assert_response :success
    end

    test 'should list account children' do
      children_size = 3
      # create children
      (1..children_size).each do |i|
        create_account(@tenant, USERNAME, PASSWORD, "Kaui test#{i}", nil, nil, @account.account_id)
      end

      parameters = {
        search: { value: @account.account_id },
        format: :json,
        account_id: @account.account_id
      }
      get :pagination, params: parameters
      assert_response :success

      body = MultiJson.decode(@response.body)

      assert_instance_of Array, body['data']
      assert_equal children_size, body['data'].size
      assert_nil body['error']
    end
  end
end
