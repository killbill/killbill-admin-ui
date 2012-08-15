require 'test_helper'

class Kaui::PluginInfoPropertyTest < ActiveSupport::TestCase
  fixtures :plugin_info_properties

  keys = [:accountId, :type, :cardHolderName, :cardType, :expirationDate, :maskNumber,
          :address1, :address2, :city, :postalCode, :state, :country]

  test "can serialize from json" do
    keys.each do |key|
      as_json = plugin_info_properties("plugin_info_property_#{key.to_s}".to_sym)
      plugin_info_property = Kaui::PluginInfoProperty.new(as_json)

      assert_equal as_json["isUpdatable"], plugin_info_property.is_updatable
      assert_equal as_json["key"], plugin_info_property.key
      assert_equal key.to_s, plugin_info_property.key
      assert_equal as_json["value"], plugin_info_property.value
    end
  end
end