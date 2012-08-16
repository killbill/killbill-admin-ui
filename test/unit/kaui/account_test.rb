require 'test_helper'

class Kaui::AccountTest < ActiveSupport::TestCase
  fixtures :accounts

  test "can serialize from json" do
    as_json = accounts(:pierre)
    pierre = Kaui::Account.new(as_json)

    assert_equal as_json["accountId"], pierre.account_id
    assert_equal as_json["address1"], pierre.address1
    assert_equal as_json["address2"], pierre.address2
    assert_equal as_json["company"], pierre.company
    assert_equal as_json["country"], pierre.country
    assert_equal as_json["currency"], pierre.currency
    assert_equal as_json["email"], pierre.email
    assert_equal as_json["externalKey"], pierre.external_key
    assert_equal as_json["name"], pierre.name
    assert_equal as_json["paymentMethodId"], pierre.payment_method_id
    assert_equal as_json["phone"], pierre.phone
    assert_equal as_json["state"], pierre.state
    assert_equal as_json["timeZone"], pierre.timezone
  end
end