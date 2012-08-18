require 'test_helper'

class Kaui::TagDefinitionTest < ActiveSupport::TestCase
  fixtures :tag_definitions

  test "can serialize from json" do
    as_json = tag_definitions(:payment_plan)
    tag_definition = Kaui::TagDefinition.new(as_json)

    assert_equal as_json["id"], tag_definition.id
    assert_equal as_json["name"], tag_definition.name
    assert_equal as_json["description"], tag_definition.description
    assert !tag_definition.is_system_tag?

    as_json = tag_definitions(:auto_pay_off)
    tag_definition = Kaui::TagDefinition.new(as_json)

    assert_equal as_json["id"], tag_definition.id
    assert_equal as_json["name"], tag_definition.name
    assert_equal as_json["description"], tag_definition.description
    assert tag_definition.is_system_tag?
  end
end