# frozen_string_literal: true

require 'test_helper'

module Kaui
  class UuidHelperTest < ActionView::TestCase
    # include Kaui::UuidHelper

    test 'can truncate' do
      assert_equal '04bdf7b6-...-ab062d33c425', truncate_uuid('04bdf7b6-a95d-4a08-9990-ab062d33c425')
    end

    test 'can create a popover' do
      object_id = SecureRandom.uuid
      expected_markup = %(<span id="#{object_id}-popover" class="object-id-popover" data-id="#{object_id}" data-placement="right">#{truncate_uuid(object_id)}</span)
      assert_dom_equal expected_markup, object_id_popover(object_id)
    end
  end
end
