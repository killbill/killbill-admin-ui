# frozen_string_literal: true

module Kaui
  module PluginHelper
    def plugin_repository
      installed_plugins
    end

    private

    def installed_plugins
      installed_plugins = []
      nodes_info = KillBillClient::Model::NodesInfo.nodes_info(Kaui.current_tenant_user_options(current_user, session)) || []
      plugins_info = nodes_info.empty? ? [] : (nodes_info.first.plugins_info || [])

      plugins_info.each do |plugin|
        next if plugin.version.nil?
        # do not allow duplicate
        next if installed_plugins.any? { |p| p[:plugin_name].eql?(plugin.plugin_name) }

        plugin_key = plugin.plugin_key
        installed_plugins << {
          # Unique identifier chosen by the user and used for kpm operations
          plugin_key:,
          # Notes:
          #   * plugin.plugin_name comes from kpm and is arbitrary (see Utils.get_plugin_name_from_file_path in the kpm codebase for instance)
          #   * plugin_name here is the plugin name as seen by Kill Bill and is typically defined in the Activator.java (this value is the one that matters for plugin configuration)
          #   * The mapping here is a convention we've used over the years and is no way enforced anywhere - it likely won't work for proprietary plugins (the user would need to specify it by toggling the input on the UI)
          plugin_name: "killbill-#{plugin_key}",
          installed: true
        }
      end

      # to_s to handle nil
      installed_plugins.sort! { |a, b| a[:plugin_key].to_s <=> b[:plugin_key].to_s }
    end
  end
end
