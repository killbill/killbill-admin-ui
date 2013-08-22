require 'test_helper'

class Kaui::TagDefinitionTest < ActiveSupport::TestCase
  fixtures :tag_definitions

  test "can serialize from json" do
    # Test user tag
    as_json = tag_definitions(:payment_plan)
    tag_definition = Kaui::TagDefinition.new(as_json)

    assert_equal as_json["id"], tag_definition.id
    assert_equal as_json["name"], tag_definition.name
    assert_equal as_json["description"], tag_definition.description
    assert_equal as_json["applicableObjectTypes"], tag_definition.applicable_object_types
    assert !tag_definition.is_system_tag?

    # Test system tag
    as_json = tag_definitions(:auto_pay_off)
    tag_definition = Kaui::TagDefinition.new(as_json)

    assert_equal as_json["id"], tag_definition.id
    assert_equal as_json["name"], tag_definition.name
    assert_equal as_json["description"], tag_definition.description
    assert_equal as_json["applicableObjectTypes"], tag_definition.applicable_object_types
    assert tag_definition.is_system_tag?
  end

  test "can find all per object type" do
    assert_equal 3, Kaui::TagDefinition.all.size
    assert_equal 2, Kaui::TagDefinition.all_for_account({}).size
    assert_equal 1, Kaui::TagDefinition.all_for_invoice({}).size
    assert_equal 1, Kaui::TagDefinition.all_for_tag_definition({}).size
  end
end
