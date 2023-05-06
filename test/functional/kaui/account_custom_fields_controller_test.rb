# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountCustomFieldsControllerTest < Kaui::FunctionalTestHelper
    test 'should list all account custom fields' do
      new_account = create_account(@tenant)

      # set a custom field
      created_custom_field = Kaui::CustomField.new
      created_custom_field.object_id = new_account.account_id
      created_custom_field.object_type = 'ACCOUNT'
      created_custom_field.name = 'test'
      created_custom_field.value = 'value'

      new_account.add_custom_field(created_custom_field, 'Kaui test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))

      # get custom field list
      get :index, params: { account_id: new_account.account_id }
      assert_response :success
      custom_fields_from_response = extract_value_from_input_field('custom-fields').gsub!('&quot;', '"')
      assert_not_nil custom_fields_from_response
      custom_fields = JSON.parse(custom_fields_from_response)
      assert_equal 1, custom_fields.count
      assert_equal 'ACCOUNT', custom_fields[0][1]
      assert_equal 'test', custom_fields[0][2]
      assert_equal 'value', custom_fields[0][3]
    end
  end
end
