require 'test_helper'

class Kaui::UuidHelperTest < ActiveSupport::TestCase

  include Kaui::UuidHelper

  test 'can truncate' do
    assert_equal '04bdf7b6-...-ab062d33c425', truncate_uuid('04bdf7b6-a95d-4a08-9990-ab062d33c425')
  end
end
