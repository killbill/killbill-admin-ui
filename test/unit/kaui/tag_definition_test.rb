# frozen_string_literal: true

require 'test_helper'

module Kaui
  class TagDefinitionTest < ActiveSupport::TestCase
    test 'can detect system tags' do
      1.upto(9).each do |i|
        assert Kaui::TagDefinition.new(id: "00000000-0000-0000-0000-00000000000#{i}").system_tag?
      end
      assert !Kaui::TagDefinition.new(id: SecureRandom.uuid).system_tag?
    end
  end
end
