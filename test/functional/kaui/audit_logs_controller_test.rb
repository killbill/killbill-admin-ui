require 'test_helper'
require 'nokogiri'

class Kaui::AuditLogsControllerTest < Kaui::FunctionalTestHelper
  OBJECT_WITH_HISTORY = %w[ACCOUNT ACCOUNT_EMAIL CUSTOM_FIELD PAYMENT_ATTEMPT PAYMENT PAYMENT_METHOD TRANSACTION TAG]

  test 'should list all account audit logs' do
    new_account = create_account(@tenant)

    get :index, :account_id => new_account.account_id
    assert_response :success
    audit_logs_from_response = get_value_from_input_field('audit-logs').gsub!('&quot;','"');
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

    get :index, :account_id => new_account.account_id
    assert_response :success
    audit_logs_from_response = get_value_from_input_field('audit-logs').gsub!('&quot;','"');
    assert_not_nil audit_logs_from_response
    audit_logs = JSON.parse(audit_logs_from_response)

    audit_logs.each do |audit_log|
      if OBJECT_WITH_HISTORY.include?(audit_log[2])
        anchor = Nokogiri::HTML(audit_log[1]).css('a')
        get :history, :account_id => new_account.account_id, :object_id => anchor[0]['data-object-id'], :object_type => audit_log[2]
        assert_response :success

        audit_logs_with_history = JSON.parse(@response.body)['audits']

        if audit_log[2] == 'ACCOUNT'
          assert_equal 3, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
          assert_nil audit_logs_with_history[0]['history']['notes']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
          assert_not_nil audit_logs_with_history[1]['history']['notes']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
          assert_not_nil audit_logs_with_history[2]['history']['paymentMethodId']
        elsif audit_log[2] == 'PAYMENT'
          assert_equal 2, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
        elsif audit_log[2] == 'PAYMENT_METHOD'
          assert_equal 1, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
        elsif audit_log[2] == 'TRANSACTION'
          assert_equal 2, audit_logs_with_history.count
          assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
          assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
        end

      end
    end

  end

  private
  def add_a_note(account)
    account.notes = 'I am a note'
    account.update(false, 'Kaui log test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
  end
end
