require 'test_helper'

class Kaui::MoneyHelperTest < ActiveSupport::TestCase

  include Kaui::MoneyHelper

  test 'can list currencies' do
    assert_equal 164, currencies.size
  end
end
