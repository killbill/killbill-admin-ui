require 'test_helper'

class Kaui::InvoiceItemTest < ActiveSupport::TestCase
  fixtures :invoice_items

  test "can serialize from json" do
    as_json = invoice_items(:recurring_item_for_pierre)
    invoice = Kaui::InvoiceItem.new(as_json)

    assert_equal as_json["invoiceItemId"], invoice.invoice_item_id
    assert_equal as_json["invoiceId"], invoice.invoice_id
    assert_equal as_json["accountId"], invoice.account_id
    assert_equal as_json["bundleId"], invoice.bundle_id
    assert_equal as_json["subscriptionId"], invoice.subscription_id
    assert_equal as_json["planName"], invoice.plan_name
    assert_equal as_json["phaseName"], invoice.phase_name
    assert_equal as_json["description"], invoice.description
    assert_equal as_json["startDate"], invoice.start_date
    assert_equal as_json["endDate"], invoice.end_date
    assert_equal as_json["amount"], invoice.amount
    assert_equal as_json["currency"], invoice.currency
  end
end