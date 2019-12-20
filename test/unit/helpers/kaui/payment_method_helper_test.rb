require 'test_helper'

class PaymentMethodHelperTest < ActionView::TestCase

  include Kaui::PaymentMethodHelper

  test 'is_json?' do
    assert !is_json?(5)
    assert !is_json?('true')
    assert !is_json?(false)
    assert !is_json?("")
    assert !is_json?(nil)
    assert is_json?('[1, 2, 3]')
    assert is_json?('{"value": "New", "onclick": "CreateNewDoc()"}')
    assert !is_json?('{"value" => "New", "onclick": "CreateNewDoc()"}')
  end
end
