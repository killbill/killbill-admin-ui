require 'test_helper'

class Kaui::AuditLogsControllerTest < Kaui::FunctionalTestHelper

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

     get :index, :account_id => new_account.account_id
    assert_response :success

    get :history, :account_id => new_account.account_id, :object_id => new_account.account_id, :object_type => 'ACCOUNT'
    assert_response :success

    audit_logs_with_history = JSON.parse(@response.body)['audits']
    assert_equal 2, audit_logs_with_history.count
    assert_equal 'INSERT', audit_logs_with_history[0]['changeType']
    assert_nil audit_logs_with_history[0]['history']['notes']
    assert_equal 'UPDATE', audit_logs_with_history[1]['changeType']
    assert_not_nil audit_logs_with_history[1]['history']['notes']

  end

  private
  def add_a_note(account)
    account.notes = 'I am a note'
    account.update(false, 'Kaui log test', nil, nil, build_options(@tenant, USERNAME, PASSWORD))
  end
end
