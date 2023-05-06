# frozen_string_literal: true

require 'test_helper'

class PaymentMethodHelperTest < ActionView::TestCase
  include Kaui::PaymentMethodHelper

  test 'json?' do
    assert !json?(5)
    assert !json?('true')
    assert !json?(false)
    assert !json?('')
    assert !json?(nil)
    assert json?('[1, 2, 3]')
    assert json?('{"value": "New", "onclick": "CreateNewDoc()"}')
    assert !json?('{"value" => "New", "onclick": "CreateNewDoc()"}')
  end
end
