require 'test_helper'

class Kaui::InvoiceTest < ActiveSupport::TestCase
  fixtures :invoices

  test "can serialize from json" do
    as_json = invoices(:invoice_for_pierre)
    invoice = Kaui::Invoice.new(as_json)
    
    assert_equal as_json["amount"], invoice.amount
    assert_equal as_json["cba"], invoice.credit_balance_adjustment
    assert_equal as_json["creditAdj"], invoice.credit_adjustment
    assert_equal as_json["refundAdj"], invoice.refund_adjustment
    assert_equal as_json["invoiceId"], invoice.invoice_id
    assert_equal as_json["invoiceDate"], invoice.invoice_date
    assert_equal as_json["targetDate"], invoice.target_date
    assert_equal as_json["invoiceNumber"], invoice.invoice_number
    assert_equal as_json["accountId"], invoice.account_id
  end
end