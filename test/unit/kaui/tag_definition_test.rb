require 'test_helper'

class Kaui::TagDefinitionTest < ActiveSupport::TestCase

  test 'can detect system tags' do
    1.upto(9).each do |i|
      assert Kaui::TagDefinition.new(:id => '00000000-0000-0000-0000-00000000000' + i.to_s).is_system_tag?
    end
    assert !Kaui::TagDefinition.new(:id => SecureRandom.uuid).is_system_tag?
  end
end
