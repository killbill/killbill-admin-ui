# frozen_string_literal: true

require 'test_helper'

class PaymentMethodHelperTest < ActionView::TestCase
  include Kaui::PaymentMethodHelper

  test 'json?' do
    assert_not json?(5)
    assert_not json?('true')
    assert_not json?(false)
    assert_not json?('')
    assert_not json?(nil)
    assert json?('[1, 2, 3]')
    assert json?('{"value": "New", "onclick": "CreateNewDoc()"}')
    assert_not json?('{"value" => "New", "onclick": "CreateNewDoc()"}')
  end
end
