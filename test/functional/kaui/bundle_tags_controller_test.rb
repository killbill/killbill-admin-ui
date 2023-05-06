# frozen_string_literal: true

require 'test_helper'

module Kaui
  class BundleTagsControllerTest < Kaui::FunctionalTestHelper
    test 'should handle Kill Bill errors when getting edit screen' do
      get :edit, params: { account_id: @account.account_id }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Required parameter missing: bundle_id', flash[:error]

      bundle_id = SecureRandom.uuid.to_s
      get :edit, params: { account_id: @account.account_id, bundle_id: }
      assert_redirected_to account_path(@account.account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{bundle_id} type=BUNDLE doesn't exist!", flash[:error]
    end

    test 'should get edit' do
      get :edit, params: { account_id: @account.account_id, bundle_id: @bundle.bundle_id }
      assert_response 200
      assert_not_nil assigns(:bundle_id)
      assert_not_nil assigns(:tag_names)
      assert_not_nil assigns(:available_tags)
    end
  end
end
