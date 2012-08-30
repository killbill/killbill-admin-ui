require 'test_helper'

class Kaui::OverdueStateTest < ActiveSupport::TestCase
  fixtures :overdue_states

  test "can serialize from json" do
    as_json = overdue_states(:od1)
    od1 = Kaui::OverdueState.new(as_json)

    assert_equal as_json["name"], od1.name
    assert_equal as_json["externalMessage"], od1.external_message
    assert_equal as_json["daysBetweenPaymentRetries"], od1.days_between_payment_retries
    assert_equal as_json["disableEntitlementAndChangesBlocked"], od1.disable_entitlement_and_changes_blocked
    assert_equal as_json["blockChanges"], od1.block_changes
    assert_equal as_json["clearState"], od1.clear_state
    assert_equal as_json["reevaluationIntervalDays"], od1.reevaluation_interval_days
  end
end