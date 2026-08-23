# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountTimelinesControllerTest < Kaui::FunctionalTestHelper
    test 'should show the timeline page' do
      get :show, params: { account_id: @account.account_id }
      assert_response :ok

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:bundles)
      assert_not_nil assigns(:bundle_keys_by_invoice_id)
      assert_not_nil assigns(:bundle_names_by_invoice_id)
      assert_not_nil assigns(:invoices)
      assert_not_nil assigns(:payments)
      assert_not_nil assigns(:invoices_by_id)
      assert_not_nil assigns(:account_blocking_states)

      assert_equal @account.account_id, assigns(:account).account_id
      assert_equal @invoice_item.invoice_id, assigns(:invoices_by_id)[@invoice_item.invoice_id].invoice_id
    end

    test 'should show a subscription blocking state and an account-level blocking state on the timeline' do
      @bundle.subscriptions.first.set_blocking_state('BLOCKED', 'kaui-test-sub', true, true, true, nil,
                                                     USERNAME, nil, nil, options)
      @account.set_blocking_state('BLOCKED', 'kaui-test-account', true, true, true, nil,
                                  USERNAME, nil, nil, options)

      get :show, params: { account_id: @account.account_id }
      assert_response :ok

      bundle = assigns(:bundles).find { |b| b.bundle_id == @bundle.bundle_id }
      # A subscription-level blocking state surfaces as PAUSE_ENTITLEMENT/PAUSE_BILLING events,
      # not as a SERVICE_STATE_CHANGE event (those are only emitted for account-level blocking states)
      event = bundle.subscriptions.flat_map(&:events).find { |e| e.event_type == 'PAUSE_ENTITLEMENT' && e.service_name == 'kaui-test-sub' }
      assert_not_nil event
      assert_equal 'BLOCKED', event.service_state_name

      account_blocking_state = assigns(:account_blocking_states).find { |bs| bs.service == 'kaui-test-account' }
      assert_not_nil account_blocking_state
      assert_equal 'BLOCKED', account_blocking_state.state_name

      assert_includes @response.body, 'kaui-test-sub'
      assert_includes @response.body, 'kaui-test-account'
    end

    test 'should include blocking states in the CSV download' do
      @bundle.subscriptions.first.set_blocking_state('BLOCKED', 'kaui-test-sub', true, true, true, nil,
                                                     USERNAME, nil, nil, options)
      @account.set_blocking_state('BLOCKED', 'kaui-test-account', true, true, true, nil,
                                  USERNAME, nil, nil, options)

      get :download, params: { account_id: @account.account_id, eventType: 'ALL' }
      assert_response :ok

      assert_includes @response.body, 'kaui-test-sub'
      assert_includes @response.body, 'kaui-test-account'
      assert_includes @response.body, 'SERVICE_STATE_CHANGE'
    end
  end
end
