# frozen_string_literal: true

require 'test_helper'

module Kaui
  class QueuesControllerTest < Kaui::FunctionalTestHelper
    test 'should get queues' do
      get :index, params: { account_id: @account.account_id, with_history: true }
      now = assigns(:now)
      queues_entries = assigns(:queues_entries)

      assert_not_nil now
      assert_not_nil queues_entries
      assert queues_entries['busEvents'].size.positive?

      assert_response :success
    end

    test 'should get min_date error' do
      get :index, params: { account_id: @account.account_id, with_history: true, min_date: 'char date' }

      assert_equal 'Invalid min date format', flash[:error]
      assert_response 302
    end

    test 'should get max_date error' do
      get :index, params: { account_id: @account.account_id, with_history: true, max_date: 'char date' }

      assert_equal 'Invalid max date format', flash[:error]
      assert_response 302
    end
  end
end
