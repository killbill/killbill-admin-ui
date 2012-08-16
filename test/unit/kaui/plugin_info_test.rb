require 'test_helper'

class Kaui::PluginInfoTest < ActiveSupport::TestCase
  fixtures :plugin_infos, :plugin_info_properties

  include Kaui::PluginInfosHelperTest

  test "can serialize from json" do
    as_json = plugin_infos(:plugin_info_for_pierre)
    plugin_info = create_plugin_info(as_json)

    assert_equal as_json["externalPaymentId"], plugin_info.external_payment_id
    @@plugin_info_keys.each_with_index do |key, i|
      assert_equal plugin_info_properies[i]["key"], plugin_info.properties[i].key
      assert_equal plugin_info_properies[i]["value"], plugin_info.properties[i].value
      assert_equal plugin_info_properies[i]["is_updatable"], plugin_info.properties[i].is_updatable
    end
  end
end