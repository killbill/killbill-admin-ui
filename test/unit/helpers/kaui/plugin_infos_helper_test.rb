require 'test_helper'

module Kaui::PluginInfosHelperTest
  @@plugin_info_keys = [:accountId, :type, :cardHolderName, :cardType, :expirationDate, :maskNumber,
                        :address1, :address2, :city, :postalCode, :state, :country]

  def plugin_info_properies
    properties = []
    @@plugin_info_keys.each do |key|
      as_json = plugin_info_properties("plugin_info_property_#{key.to_s}".to_sym)
      properties << Kaui::PluginInfoProperty.new(as_json).to_hash
    end
    properties
  end

  def create_plugin_info(plugin_info_json)
    plugin_info_json["properties"] = plugin_info_properies
    Kaui::PluginInfo.new(plugin_info_json)
  end
end
