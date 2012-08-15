require 'test_helper'

class Kaui::PluginInfoTest < ActiveSupport::TestCase
  fixtures :plugin_infos, :plugin_info_properties

  keys = [:accountId, :type, :cardHolderName, :cardType, :expirationDate, :maskNumber,
          :address1, :address2, :city, :postalCode, :state, :country]

  test "can serialize from json" do
    properties = []
    keys.each do |key|
      as_json = plugin_info_properties("plugin_info_property_#{key.to_s}".to_sym)
      properties << Kaui::PluginInfoProperty.new(as_json).to_hash
    end

    as_json = plugin_infos(:plugin_info_for_pierre)
    as_json["properties"] = properties

    plugin_info = Kaui::PluginInfo.new(as_json)
    assert_equal as_json["externalPaymentId"], plugin_info.external_payment_id
    keys.each_with_index do |key, i|
      assert_equal properties[i]["key"], plugin_info.properties[i].key
      assert_equal properties[i]["value"], plugin_info.properties[i].value
      assert_equal properties[i]["is_updatable"], plugin_info.properties[i].is_updatable
    end
  end
end