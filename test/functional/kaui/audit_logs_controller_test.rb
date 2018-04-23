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
end
