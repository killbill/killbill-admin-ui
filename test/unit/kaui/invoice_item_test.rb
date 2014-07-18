require 'test_helper'

class Kaui::InvoiceItemTest < ActiveSupport::TestCase

  test 'can convert to money' do
    invoice_item = Kaui::InvoiceItem.new(:amount => 12.42, :currency => 'USD')

    assert_equal 1242, invoice_item.amount_to_money.cents
    assert_equal 'USD', invoice_item.amount_to_money.currency_as_string
  end
end
