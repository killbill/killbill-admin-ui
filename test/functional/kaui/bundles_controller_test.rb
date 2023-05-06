# frozen_string_literal: true

require 'test_helper'

module Kaui
  class BundlesControllerTest < Kaui::FunctionalTestHelper
    test 'should be redirected if an invalid account id was specified in index screen' do
      account_id = SecureRandom.uuid.to_s
      get :index, params: { account_id: }
      assert_redirected_to account_path(account_id)
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{account_id} type=ACCOUNT doesn't exist!", flash[:error]
    end

    test 'should get index with existing tags' do
      tag_definition_ids = []
      def1 = create_tag_definition(SecureRandom.uuid.to_s[0..19], @tenant)
      tag_definition_ids << def1
      tag_definition_ids << def1
      def2 = create_tag_definition(SecureRandom.uuid.to_s[0..19], @tenant)
      tag_definition_ids << def2

      add_tags(@bundle, tag_definition_ids, @tenant)
      get :index, params: { account_id: @bundle.account_id }
      assert_response 200
      assert_not_nil assigns(:account)
      assert_not_nil assigns(:bundles)
      assert_not_nil assigns(:tags_per_bundle)
      assert_equal 2, assigns(:tags_per_bundle)[@bundle.bundle_id].size
    end

    test 'should handle Kill Bill errors during transfer' do
      post :do_transfer, params: { id: @bundle.bundle_id }
      assert_redirected_to home_path
      assert_equal 'Required parameter missing: new_account_key', flash[:error]

      new_account_key = SecureRandom.uuid.to_s
      post :do_transfer, params: { id: @bundle.bundle_id, new_account_key: }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{new_account_key} type=ACCOUNT doesn't exist!", flash[:error]

      bundle_id = SecureRandom.uuid.to_s
      post :do_transfer, params: { id: bundle_id, new_account_key: @account2.external_key }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{bundle_id} type=BUNDLE doesn't exist!", flash[:error]
    end

    test 'should get transfer' do
      get :transfer, params: { id: @bundle.bundle_id }
      assert_response 200
      assert_not_nil assigns(:bundle_id)
    end

    test 'should transfer bundle default policy' do
      check_bundle_owner(@account.account_id)

      post :do_transfer,
           params: {
             id: @bundle.bundle_id,
             new_account_key: @account2.external_key
           }
      assert_redirected_to account_bundles_path(@account2.account_id)
      assert_equal 'Bundle was successfully transferred', flash[:notice]

      check_bundle_owner(@account2.account_id)
    end

    test 'should transfer bundle immediately' do
      check_bundle_owner(@account.account_id)

      post :do_transfer,
           params: {
             id: @bundle.bundle_id,
             new_account_key: @account2.external_key,
             billing_policy: 'IMMEDIATE'
           }
      assert_redirected_to account_bundles_path(@account2.account_id)
      assert_equal 'Bundle was successfully transferred', flash[:notice]

      check_bundle_owner(@account2.account_id)
    end

    test 'should expose restful endpoint' do
      get :restful_show, params: { id: @bundle.bundle_id }
      assert_redirected_to account_bundles_path(@bundle.account_id)

      get :restful_show, params: { id: @bundle.external_key }
      assert_redirected_to account_bundles_path(@bundle.account_id)
    end

    test 'should get pause_resume ' do
      get :pause_resume, params: { id: @bundle.bundle_id }
      assert_response :success
      assert input_field?('pause_requested_date')
      assert input_field?('resume_requested_date')
    end

    test 'should put bundle on pause and resume' do
      expected_response_path = "/accounts/#{@account.account_id}/bundles"
      bundle = create_bundle(@account, @tenant)

      # put bundle on pause
      put :do_pause_resume, params: { id: bundle.bundle_id, account_id: @account.account_id, pause_requested_date: DateTime.now.strftime('%F') }
      assert_response :redirect
      assert_equal 'Bundle was successfully paused', flash[:notice]
      # validate redirect path
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

      # resume bundle on pause
      put :do_pause_resume, params: { id: bundle.bundle_id, account_id: @account.account_id, resume_requested_date: DateTime.now.strftime('%F') }
      assert_response :redirect
      assert_equal 'Bundle was successfully resumed', flash[:notice]
      # validate redirect path
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
    end

    private

    def create_tag_definition(tag_definition_name, tenant, username = USERNAME, password = PASSWORD, reason = nil, comment = nil)
      input = Kaui::TagDefinition.new(tag_definition_name)
      input.name = tag_definition_name
      input.description = 'something'
      input.applicable_object_types = ['BUNDLE']
      tag_def = input.create(username, reason, comment, build_options(tenant, username, password))
      tag_def.id
    end

    def add_tags(bundle, tag_definition_ids, tenant, username = USERNAME, password = PASSWORD, reason = nil, comment = nil)
      bundle.set_tags(tag_definition_ids, username, reason, comment, build_options(tenant, username, password))
    end

    def check_bundle_owner(new_owner)
      assert_equal new_owner, Kaui::Bundle.find_by_external_key(@bundle.external_key, false, options).account_id
    end
  end
end
