# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountTagsControllerTest < Kaui::FunctionalTestHelper
    test 'should handle Kill Bill errors when getting edit screen' do
      account_id = '1234'
      get :edit, params: { account_id: }
      assert_redirected_to account_path(account_id)
    end

    test 'should get edit' do
      get :edit, params: { account_id: @account.account_id }
      assert_response 200
      assert_not_nil assigns(:account_id)
      assert_not_nil assigns(:tag_names)
      assert_not_nil assigns(:available_tags)
    end

    test 'should update tags' do
      post :update,
           params: {
             account_id: @account.account_id,
             'tag_00000000-0000-0000-0000-000000000001': 'AUTO_PAY_OFF',
             'tag_00000000-0000-0000-0000-000000000005': 'MANUAL_PAY',
             'tag_00000000-0000-0000-0000-000000000003': 'OVERDUE_ENFORCEMENT_OFF'
           }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Account tags successfully set', flash[:notice]
    end

    test 'should list all account tags' do
      new_account = create_account(@tenant)
      # set some tags
      post :update,
           params: {
             account_id: new_account.account_id,
             'tag_00000000-0000-0000-0000-000000000001': 'AUTO_PAY_OFF',
             'tag_00000000-0000-0000-0000-000000000005': 'MANUAL_PAY',
             'tag_00000000-0000-0000-0000-000000000003': 'OVERDUE_ENFORCEMENT_OFF'
           }
      assert_redirected_to account_path(new_account.account_id)
      assert_equal 'Account tags successfully set', flash[:notice]

      # get tag list
      get :index, params: { account_id: new_account.account_id }
      assert_response :success
      tags_from_response = extract_value_from_input_field('tags').gsub!('&quot;', '"')
      assert_not_nil tags_from_response
      assert_equal 3, JSON.parse(tags_from_response).count
    end
  end
end
