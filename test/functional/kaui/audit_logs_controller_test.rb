# frozen_string_literal: true

require 'test_helper'
require 'nokogiri'

module Kaui
  class AuditLogsControllerTest < Kaui::FunctionalTestHelper
    OBJECT_WITH_HISTORY = %w[ACCOUNT ACCOUNT_EMAIL CUSTOM_FIELD PAYMENT_ATTEMPT PAYMENT PAYMENT_METHOD TRANSACTION TAG].freeze

    test 'should list all account audit logs' do
      new_account = create_account(@tenant)

      get :index, params: { account_id: new_account.account_id }
      assert_response :success
      audit_logs_from_response = extract_value_from_input_field('audit-logs').gsub!('&quot;', '"')
      assert_not_nil audit_logs_from_response
      audit_logs = JSON.parse(audit_logs_from_response)
      assert_equal 1, audit_logs.count
      assert_equal 'ACCOUNT', audit_logs[0][2]
      assert_equal 'INSERT', audit_logs[0][3]
    end

    test 'should get audit logs with history' do
      new_account = create_account(@tenant)
      add_a_note(new_account)
      create_payment_method(true, new_account, @tenant)
      create_payment(nil, new_account, @tenant)

      get :index, params: { account_id: new_account.account_id }
      assert_response :success
      audit_logs_from_response = extract_value_from_input_field('audit-logs').gsub!('&quot;', '"')
      assert_not_nil audit_logs_from_response
      audit_logs = JSON.parse(audit_logs_from_response)

      audit_logs.each do |audit_log|
        next unless OBJECT_WITH_HISTORY.include?(audit_log[2])

        anchor = Nokogiri::HTML(audit_log[1]).css('a')
        get :history, params: { account_id: new_account.account_id, object_id: anchor[0]['data-object-id'], object_type: audit_log[2] }
        assert_response :success

        audit_logs_with_history = JSON.parse(@response.body)['audits']

        case audit_log[2]
        when 'ACCOUNT'
          assert_equal 3, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
          assert_nil audit_logs_with_history[0]['history']['notes']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
          assert_not_nil audit_logs_with_history[1]['history']['notes']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
          assert_not_nil audit_logs_with_history[2]['history']['paymentMethodId']
        when 'PAYMENT', 'TRANSACTION'
          assert_equal 2, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
        when 'PAYMENT_METHOD'
          assert_equal 1, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
        end
      end
    end

    test 'should download audit logs data' do
      get :download, params: { account_id: @account.account_id }
      assert_response :success
      assert_equal 'text/csv', @response.header['Content-Type']
      assert_includes @response.header['Content-Disposition'], "filename=\"audit-logs-#{Date.today}.csv\""
      assert_includes @response.body, @payment.payment_id
      assert_includes @response.body, @account.account_id
    end

    private

    def add_a_note(account)
      account.notes = 'I am a note'
      account.update(false, 'Kaui log test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
    end
  end
end
