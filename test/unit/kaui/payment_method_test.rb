require 'test_helper'

class Kaui::PaymentMethodTest < ActiveSupport::TestCase
  fixtures :payment_methods, :plugin_infos, :plugin_info_properties

  include Kaui::PluginInfosHelperTest

  test "can serialize from json" do
    as_json = plugin_infos(:plugin_info_for_pierre)
    plugin_info = create_plugin_info(as_json)

    as_json = payment_methods(:payment_method_for_pierre)
    as_json["pluginInfo"] = plugin_info
    payment_method = Kaui::PaymentMethod.new(as_json)

    assert_equal as_json["accountId"], payment_method.account_id
    assert_equal as_json["isDefault"], payment_method.is_default
    assert_equal as_json["paymentMethodId"], payment_method.payment_method_id
    assert_equal as_json["pluginName"], payment_method.plugin_name
    @@plugin_info_keys.each_with_index do |key, i|
      assert_equal plugin_info_properies[i]["key"], payment_method.plugin_info.properties[i].key
      assert_equal plugin_info_properies[i]["value"], payment_method.plugin_info.properties[i].value
      assert_equal plugin_info_properies[i]["is_updatable"], payment_method.plugin_info.properties[i].is_updatable
    end
  end
end