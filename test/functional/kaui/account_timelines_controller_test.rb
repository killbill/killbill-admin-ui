# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountTimelinesControllerTest < Kaui::FunctionalTestHelper
    test 'should show the timeline page' do
      get :show, params: { account_id: @account.account_id }
      assert_response 200

      assert_not_nil assigns(:account)
      assert_not_nil assigns(:bundles)
      assert_not_nil assigns(:bundle_keys_by_invoice_id)
      assert_not_nil assigns(:bundle_names_by_invoice_id)
      assert_not_nil assigns(:invoices)
      assert_not_nil assigns(:payments)
      assert_not_nil assigns(:invoices_by_id)

      assert_equal @account.account_id, assigns(:account).account_id
      assert_equal @invoice_item.invoice_id, assigns(:invoices_by_id)[@invoice_item.invoice_id].invoice_id
    end
  end
end
